defmodule Systems.Account.MockAuth do
  def configured?() do
    Application.get_env(:core, :account, [])
    |> Keyword.get(:auth_providers, [])
    |> Enum.member?(:mock)
  end
end

defmodule Systems.Account.MockAuth.InitiatorPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if Systems.Account.MockAuth.configured?() do
      conn
      |> Systems.Account.UserAuth.sign_out_current_user()
      |> Phoenix.Controller.redirect(to: "/auth/mock/callback")
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end
end

defmodule Systems.Account.MockAuth.CallbackController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  alias Core.Repo
  alias Systems.Account.User

  def authenticate(conn, _params) do
    if Systems.Account.MockAuth.configured?() do
      {user, first_time?} = find_or_create_mock_user()

      conn
      |> Systems.Account.UserAuth.sign_out_current_user()
      |> Systems.Account.UserAuth.log_in_user(user, first_time?)
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp find_or_create_mock_user() do
    case Repo.get_by(User, email: "mock@example.com") do
      nil -> {create_mock_user(), true}
      user -> {user, false}
    end
  end

  defp create_mock_user() do
    sso_info = %{
      email: "mock@example.com",
      displayname: "Mock User",
      profile: %{fullname: "Mock User"},
      creator: true,
      confirmed_at: NaiveDateTime.utc_now()
    }

    {:ok, user} =
      %User{}
      |> User.sso_changeset(sso_info)
      |> Repo.insert()

    Frameworks.Signal.Public.dispatch!({:user, :created}, %{user: user})
    user
  end
end

defmodule Systems.Account.MockAuth.ResetController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Ecto.Query
  import Plug.Conn

  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.User

  def reset(conn, _params) do
    if Systems.Account.MockAuth.configured?() do
      Repo.get_by(User, email: "mock@example.com") |> delete_if_present()

      conn
      |> Systems.Account.UserAuth.sign_out_current_user()
      |> redirect(to: ~p"/user/auth/mock")
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp delete_if_present(nil), do: :ok

  defp delete_if_present(user) do
    Repo.delete_all(from(f in FeaturesModel, where: f.user_id == ^user.id))
    Repo.delete!(user)
  end
end
