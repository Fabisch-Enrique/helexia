defmodule HelexiaWeb.TeamLive.Index do
  use HelexiaWeb, :live_view

  def mount(_params, _session, socket) do
    assigns = []

    {:ok, assign(socket, assigns)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def apply_action(socket, :team, _params) do
    socket
  end
end
