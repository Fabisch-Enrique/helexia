defmodule HelexiaWeb.PageController do
  use HelexiaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
