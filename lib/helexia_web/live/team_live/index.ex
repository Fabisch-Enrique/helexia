defmodule HelexiaWeb.TeamLive.Index do
  use HelexiaWeb, :live_view

  import HelexiaWeb.TeamLive.Components

  alias Helexia.Members
  alias Helexia.Members.Member

  def mount(_params, _session, socket) do
    assigns = [founders: [], executives: [], advisors: [], member: %Member{}]

    {:ok, assign(socket, assigns)}
  end

  def handle_params(params, _uri, socket),
    do: {:noreply, apply_action(socket, socket.assigns.live_action, params)}

  def apply_action(socket, :team, _params),
    do:
      assign(socket,
        founders: Members.list_team_by_level(1),
        advisors: Members.list_team_by_level(3),
        executives: Members.list_team_by_level(2)
      )

  def apply_action(socket, :view_member, params),
    do: assign(socket, member: Member.get(params["id"]))
end
