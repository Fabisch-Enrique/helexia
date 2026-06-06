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

  def apply_action(socket, :pilot, _params) do
    pilots = Pilots.list_pilots()
    pilot_count = length(pilots)
    active_count = Enum.count(pilots, &(&1.status in ["live", "active"])) |> dbg()

    location_count =
      pilots
      |> Enum.map(fn pilot -> pilot.location.area end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> length()

    assign(socket,
      pilots: pilots,
      pilot_count: pilot_count,
      active_count: active_count,
      location_count: location_count
    )
  end
end
