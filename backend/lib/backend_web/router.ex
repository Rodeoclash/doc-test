defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :public do
    plug :put_root_layout, html: {BackendWeb.Layouts, :root_public}
  end

  pipeline :private do
    plug :put_root_layout, html: {BackendWeb.Layouts, :root_private}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BackendWeb do
    pipe_through [:browser, :public]
    get "/", PageController, :home
  end

  scope "/", BackendWeb do
    pipe_through [:browser, :private]

    live_session :organisation,
      on_mount: {BackendWeb.OrganisationHooks, :default},
      layout: {BackendWeb.Layouts, :organisation} do
    end

    live_session :document,
      on_mount: [
        {BackendWeb.OrganisationHooks, :default},
        {BackendWeb.DocumentHooks, :default}
      ],
      layout: {BackendWeb.Layouts, :organisation} do
      live "/organisations/:organisation_id/documents/:id", DocumentLive.Show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BackendWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
