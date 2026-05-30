defmodule HelexiaWeb.PilotLive.Show do
  use HelexiaWeb, :live_view

  alias Helexia.Pilots

  def mount(params, _session, socket) do
    dbg(params)

    assigns = [
      pilot: Pilots.get_pilot_by_slug!(params["slug"])
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :view_pilot, params),
    do: assign(socket, pilot: Pilots.get_pilot_by_slug!(params["slug"]))
end
