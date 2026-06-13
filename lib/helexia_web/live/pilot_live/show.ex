defmodule HelexiaWeb.PilotLive.Show do
  use HelexiaWeb, :live_view

  alias Helexia.Pilots

  def mount(params, _session, socket) do
    assigns = [
      show_video_modal: false,
      pilot: Pilots.get_pilot_by_slug!(params["slug"])
    ]

    {:ok, assign(socket, assigns)}
  end

  def handle_params(params, _uri, socket) do
    dbg(params)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("close_video_modal", _params, socket) do
    {:noreply, assign(socket, :show_video_modal, false)}
  end

  def apply_action(socket, :view_pilot, params) do
    pilot = Pilots.get_pilot_by_slug!(params["slug"])

    event_count = length(pilot.events)
    metric_count = length(pilot.metrics)
    objective_count = length(pilot.objectives)
    milestone_count = length(pilot.milestones)
    care_segment_count = length(pilot.care_segments)

    socket
    |> assign(
      event_count: event_count,
      metric_count: metric_count,
      objective_count: objective_count,
      milestone_count: milestone_count,
      care_segment_count: care_segment_count
    )
  end

  def apply_action(socket, :view_advert_show, params) do
    pilot = Pilots.get_pilot_by_slug!(params["slug"])

    event_count = length(pilot.events)
    metric_count = length(pilot.metrics)
    objective_count = length(pilot.objectives)
    milestone_count = length(pilot.milestones)
    care_segment_count = length(pilot.care_segments)

    socket
    |> assign(
      show_video_modal: true,
      event_count: event_count,
      metric_count: metric_count,
      objective_count: objective_count,
      milestone_count: milestone_count,
      care_segment_count: care_segment_count
    )
  end
end
