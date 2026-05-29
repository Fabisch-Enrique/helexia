defmodule HelexiaWeb.Router do
  use HelexiaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HelexiaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelexiaWeb do
    pipe_through :browser

    get "/landing-page", PageController, :home
    get "/contact-us", PageController, :contact
  end

  scope "/", HelexiaWeb do
    pipe_through :browser

    live_session(:home,
      on_mount: []
    ) do
      scope "/", HomeLive do
        live "/", Home, :landing_page
      end
    end
  end

  scope "/", HelexiaWeb do
    pipe_through :browser

    live_session(:team,
      on_mount: []
    ) do
      scope "/", TeamLive do
        live "/meet-the-team", Index, :team
        live "/meet-the-team/:title/:name/:id", Index, :view_member
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelexiaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:helexia, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HelexiaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
