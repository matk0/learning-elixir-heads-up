defmodule HeadsUpWeb.EffortLive do
  use HeadsUpWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :add_responders, 2000)
    end

    socket = assign(socket, responders: 0, minutes_per_responder: 10)
    {:ok, socket}
  end

  def handle_event("add", _, socket) do
    socket = update(socket, :responders, &(&1 + 3))

    {:noreply, socket}
  end

  def handle_event("set-minutes", %{"minutes" => minutes}, socket) do
    socket = assign(socket, :minutes_per_responder, String.to_integer(minutes))

    {:noreply, socket}
  end

  def handle_info(:add_responders, socket) do
    Process.send_after(self(), :add_responders, 2000)

    {:noreply, update(socket, :responders, &(&1 + 3))}
  end
end
