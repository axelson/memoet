defmodule MemoetWeb.Router do
  use MemoetWeb, :router

  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowResetPassword]

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {MemoetWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(MemoetWeb.Plugs.APIAuthPlug, otp_app: :memoet)
  end

  pipeline :api_protected do
    plug(Pow.Plug.RequireAuthenticated, error_handler: MemoetWeb.APIAuthErrorHandler)
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin_user do
    plug MemoetWeb.Plugs.AdminUserAuthPlug
  end

  pipeline :not_authenticated do
    plug Pow.Plug.RequireNotAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  scope "/", MemoetWeb do
    pipe_through [:browser, :not_authenticated]

    get "/signup", RegistrationController, :new, as: :signup
    post "/signup", RegistrationController, :create, as: :signup
  end

  scope "/", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/search", DeckController, :search, as: :search)
  end

  # Collection
  scope "/today", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/practice", CollectionController, :practice, as: :today)
    put("/practice", CollectionController, :answer, as: :today)

    get("/", CollectionController, :edit, as: :today)
    put("/", CollectionController, :update, as: :today)
  end

  # Decks & notes html
  scope "/decks", MemoetWeb do
    pipe_through [:browser, :protected]

    resources("/", DeckController) do
      resources("/notes", NoteController)
    end

    get("/:id/clone", DeckController, :clone, as: :deck)
    get("/:id/stats", DeckController, :stats, as: :deck)

    get("/:id/practice", DeckController, :practice, as: :deck)
    put("/:id/practice", DeckController, :answer, as: :deck)

    get("/:id/import", DeckController, :import, as: :deck)
  end

  # Decks & notes json
  scope "/api/decks", MemoetWeb do
    pipe_through([:api, :api_protected])

    resources("/", DeckAPIController) do
      resources("/notes", NoteAPIController)
    end

    get("/:id/practice", DeckAPIController, :practice)
    put("/:id/practice", DeckAPIController, :answer)
  end

  scope "/user", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/change-password", RegistrationController, :edit, as: :account)
    put("/change-password", RegistrationController, :update, as: :account)

    get("/account", UserController, :show, as: :account)
    post("/token", UserController, :refresh_api_token, as: :account)

    get("/config/srs", SrsConfigController, :edit, as: :srs_config)
    put("/config/srs", SrsConfigController, :update, as: :srs_config)

    post("/files", UploadController, :create, as: :upload)
  end

  scope "/" do
    pipe_through [:browser]

    pow_routes()
    pow_extension_routes()

    get "/community/:id/practice", MemoetWeb.DeckController, :public_practice, as: :community_deck
    put "/community/:id/practice", MemoetWeb.DeckController, :public_answer, as: :community_deck

    get "/community/:id", MemoetWeb.DeckController, :public_show, as: :community_deck
    get "/community", MemoetWeb.DeckController, :public_index, as: :community_deck
    get "/", MemoetWeb.PageController, :index
  end

  scope "/" do
    pipe_through [:browser, :protected, :admin_user]
    live_dashboard "/dashboard", metrics: MemoetWeb.Telemetry, ecto_repos: [Memoet.Repo]
  end
end
