defmodule HelexiaWeb.PageController do
  use HelexiaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def contact(conn, _params) do
    render(conn, :contact)
  end

  def about_us(conn, _params) do
    render(conn, :about_us)
  end
end
