defmodule HeadsUpWeb.IncidentLive.Show do
  use HeadsUpWeb, :live_view

  alias HeadsUp.Incidents
  alias HeadsUp.Responses
  alias HeadsUp.Responses.Response

  import HeadsUpWeb.CustomComponents

  on_mount {HeadsUpWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    changeset = Responses.change_response(%Response{})

    socket = assign(socket, :form, to_form(changeset))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      Incidents.subscribe(id)
    end

    incident = Incidents.get_incident!(id)

    responses = Incidents.list_responses(incident)

    socket =
      socket
      |> assign(:incident, incident)
      |> stream(:responses, responses)
      |> assign(:response_count, Enum.count(responses))
      |> assign(:page_title, incident.name)
      |> assign_async(:urgent_incidents, fn ->
        {:ok, %{urgent_incidents: Incidents.urgent_incidents(incident)}}
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="incident-show">
      <.back navigate={~p"/incidents"}>Back to incidents</.back>
      <div class="incident">
        <img src={@incident.image_path} />
        <section>
          <.badge status={@incident.status} />
          <header>
            <div>
              <h2>{@incident.name}</h2>
              <h3>{@incident.category.name}</h3>
            </div>
            <div class="priority">
              {@incident.priority}
            </div>
          </header>
          <div class="totals">
            {@response_count} Responses
          </div>
          <div class="description">
            {@incident.description}
          </div>
        </section>
      </div>
      <div class="activity">
        <div class="left">
          <div :if={@incident.status == :pending}>
            <%= if @current_user do %>
              <.form for={@form} id="response-form" phx-change="validate" phx-submit="save">
                <.input
                  field={@form[:status]}
                  type="select"
                  prompt="Choose a status"
                  options={[:enroute, :arrived, :departed]}
                />

                <.input field={@form[:note]} type="textarea" placeholder="Note..." autofocus />

                <.button>Post</.button>
              </.form>
            <% else %>
              <.link href={~p"/users/log-in"} class="button">
                Log In To Post
              </.link>
            <% end %>
          </div>
          <div id="responses" phx-update="stream">
            <.response
              :for={{dom_id, response} <- @streams.responses}
              response={response}
              id={dom_id}
            />
          </div>
        </div>
        <div class="right">
          <.urgent_incidents incidents={@urgent_incidents} />
        </div>
      </div>
    </div>
    """
  end

  def urgent_incidents(assigns) do
    ~H"""
    <section>
      <h4>Urgent Incidents</h4>
      <.async_result :let={result} assign={@incidents}>
        <:loading>
          <div class="loading">
            <div class="spinner"></div>
          </div>
        </:loading>
        <:failed :let={{:error, reason}}>
          <div class="failed">
            Yikes: {reason}
          </div>
        </:failed>
        <ul :if={@incidents.ok?} class="incidents">
          <li :for={incident <- result}>
            <.link navigate={~p"/incidents/#{incident}"}>
              <img src={incident.image_path} />{incident.name}
            </.link>
          </li>
        </ul>
      </.async_result>
    </section>
    """
  end

  def response(assigns) do
    ~H"""
    <div class="response" id={@id}>
      <span class="timeline"></span>
      <section>
        <div class="avatar">
          <.icon name="hero-user-solid" />
        </div>
        <div>
          <span class="username">
            {@response.user.username}
          </span>
          <span>
            {@response.status}
          </span>
          <blockquote>
            {@response.note}
          </blockquote>
        </div>
      </section>
    </div>
    """
  end

  def handle_event("validate", %{"response" => response_params}, socket) do
    changeset = Responses.change_response(%Response{}, response_params)

    socket = assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"response" => response_params}, socket) do
    %{incident: incident, current_user: user} = socket.assigns

    case Responses.create_response(incident, user, response_params) do
      {:ok, response} ->
        changeset = Responses.change_response(%Response{})

        socket =
          socket
          |> assign(:form, to_form(changeset))
          |> stream_insert(:responses, response, at: 0)
          |> update(:response_count, &(&1 + 1))

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end

  def handle_info({:response_created, response}, socket) do
    socket =
      socket
      |> stream_insert(:responses, response, at: 0)
      |> update(:response_count, &(&1 + 1))

    {:noreply, socket}
  end

  def handle_info({:incident_updated, incident}, socket) do
    {:noreply, assign(socket, :incident, incident)}
  end
end
