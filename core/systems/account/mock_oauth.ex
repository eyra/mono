defmodule Systems.Account.MockOAuth.InitiatorPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if mock_configured?() do
      Phoenix.Controller.redirect(conn, to: "/auth/mock/callback")
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp mock_configured?() do
    Application.get_env(:core, :account, [])
    |> Keyword.get(:oauth_providers, [])
    |> Enum.member?(:mock)
  end
end

defmodule Systems.Account.MockOAuth.CallbackController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  alias Core.Repo
  alias Systems.Account.User

  def authenticate(conn, _params) do
    if mock_configured?() do
      user = find_or_create_mock_user()
      Systems.Account.UserAuth.log_in_user(conn, user, false)
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp mock_configured?() do
    Application.get_env(:core, :account, [])
    |> Keyword.get(:oauth_providers, [])
    |> Enum.member?(:mock)
  end

  defp find_or_create_mock_user() do
    case Repo.get_by(User, email: "mock@example.com") do
      nil -> create_mock_user()
      user -> user
    end
  end

  defp create_mock_user() do
    sso_info = %{
      email: "mock@example.com",
      displayname: "Mock User",
      profile: %{fullname: "Mock User"},
      creator: true,
      verified_at: NaiveDateTime.utc_now()
    }

    {:ok, user} =
      %User{}
      |> User.sso_changeset(sso_info)
      |> Repo.insert()

    Frameworks.Signal.Public.dispatch!({:user, :created}, %{user: user})
    user
  end
end
