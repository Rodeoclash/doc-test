defmodule BackendWeb.Router do
  use BackendWeb, :router

  import BackendWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :public do
    plug :put_root_layout, html: {BackendWeb.Layouts, :root_public}
  end

  pipeline :private do
    plug :put_root_layout, html: {BackendWeb.Layouts, :root_private}
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public: landing page
  scope "/", BackendWeb do
    pipe_through [:browser, :public]
    get "/", PageController, :home
  end

  # Public: auth pages (login, register, confirm)
  scope "/", BackendWeb do
    pipe_through [:browser, :public]

    live_session :current_user,
      on_mount: [{BackendWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    live_session :require_authenticated_user,
      on_mount: [{BackendWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Authenticated: private app routes (private layout)
  scope "/", BackendWeb do
    pipe_through [:browser, :private, :require_authenticated_user]

    live_session :organisation,
      on_mount: [
        {BackendWeb.UserAuth, :require_authenticated},
        {BackendWeb.OrganisationHooks, :default}
      ],
      layout: {BackendWeb.Layouts, :organisation} do
    end

    live_session :document,
      on_mount: [
        {BackendWeb.UserAuth, :require_authenticated},
        {BackendWeb.OrganisationHooks, :default},
        {BackendWeb.DocumentHooks, :default}
      ],
      layout: {BackendWeb.Layouts, :organisation} do
      live "/organisations/:organisation_id/documents/:id", DocumentLive.Show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:backend, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
