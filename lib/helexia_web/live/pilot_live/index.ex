defmodule HelexiaWeb.PilotLive.Index do
  use HelexiaWeb, :live_view

  alias Helexia.Pilots

  def mount(_params, _session, socket) do
    assigns = [
      pilots: []
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :pilot, _params), do: assign(socket, pilots: Pilots.list_pilots())
end
