alias HeadsUp.Incidents.Incident
alias HeadsUp.Repo

import Ecto.Query

defmodule HeadsUp.Incidents do
  def subscribe(incident_id) do
    Phoenix.PubSub.subscribe(HeadsUp.PubSub, "incident:#{incident_id}")
  end

  def broadcast(incident_id, message) do
    Phoenix.PubSub.broadcast(HeadsUp.PubSub, "incident:#{incident_id}", message)
  end

  def list_incidents do
    Repo.all(Incident)
  end

  def filter_incidents(filter) do
    Incident
    |> with_status(filter["status"])
    |> with_category(filter["category"])
    |> where([i], ilike(i.name, ^"%#{filter["q"]}%"))
    |> sort(filter["sort_by"])
    |> preload(:category)
    |> Repo.all()
  end

  defp with_status(query, status)
       when status in ~w(pending resolved canceled) do
    where(query, status: ^status)
  end

  defp with_status(query, _), do: query

  defp with_category(query, slug) when slug in ["", nil], do: query

  defp with_category(query, slug) do
    from r in query,
      join: c in assoc(r, :category),
      where: c.slug == ^slug
  end

  defp sort(query, "name") do
    order_by(query, :name)
  end

  defp sort(query, "priority_desc") do
    order_by(query, desc: :priority)
  end

  defp sort(query, "priority_asc") do
    order_by(query, asc: :priority)
  end

  defp sort(query, "category") do
    from r in query,
      join: c in assoc(r, :category),
      order_by: c.name
  end

  defp sort(query, _) do
    order_by(query, :id)
  end

  def get_incident!(id) do
    Repo.get!(Incident, id)
    |> Repo.preload([:category, heroic_response: :user])
  end

  def list_responses(incident) do
    incident
    |> Ecto.assoc(:responses)
    |> preload(:user)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def urgent_incidents(incident) do
    Process.sleep(2000)

    Incident
    |> where([i], i.id != ^incident.id)
    |> order_by(:priority)
    |> limit(3)
    |> Repo.all()
  end
end
