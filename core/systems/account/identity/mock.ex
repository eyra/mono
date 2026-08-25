defmodule Systems.Account.Identity.Mock do
  @behaviour Systems.Account.Identity.Provider

  def configured?, do: Systems.Account.AuthMethods.provider?(:mock)

  def valid_email?(email), do: is_binary(email) and String.ends_with?(email, "@mock.com")

  @impl true
  def user_attrs(%{"email" => email}),
    do: %{email: email, creator: true, verified_at: NaiveDateTime.utc_now()}

  @impl true
  def get(_user), do: nil

  @impl true
  def attach(_user, _userinfo), do: {:ok, :mock}

  @impl true
  def refresh(_user, _userinfo), do: :mock
end

defmodule Systems.Account.Identity.Mock.InitiatorPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if Systems.Account.Identity.Mock.configured?() do
      email = conn.params["email"] || "example@mock.com"

      conn
      |> Systems.Account.UserAuth.sign_out_current_user()
      |> put_session(:mock_auth_email, email)
      |> Phoenix.Controller.redirect(to: "/auth/mock/callback")
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end
end

defmodule Systems.Account.Identity.Mock.CallbackController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Plug.Conn

  alias Core.Repo
  alias Systems.Account.User

  def authenticate(conn, params) do
    email = params["email"] || get_session(conn, :mock_auth_email) || "example@mock.com"

    if Systems.Account.Identity.Mock.configured?() and
         Systems.Account.Identity.Mock.valid_email?(email) do
      case Repo.get_by(User, email: email) do
        nil ->
          {:ok, %{user: user}} =
            Systems.Account.Identity.authenticate(Systems.Account.Identity.Mock, %{
              "email" => email
            })

          conn
          |> Systems.Account.UserAuth.sign_out_current_user()
          |> Systems.Account.UserAuth.log_in_user(user, true)

        user ->
          conn
          |> Systems.Account.UserAuth.sign_out_current_user()
          |> put_session(:idp_transfer, %{"email" => email, "idp" => "mock", "user_id" => user.id})
          |> redirect(to: ~p"/auth/mock/transfer")
      end
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end
end

defmodule Systems.Account.Identity.Mock.ResetController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Ecto.Query
  import Plug.Conn

  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.User

  def reset(conn, _params) do
    if Systems.Account.Identity.Mock.configured?() do
      Repo.get_by(User, email: "example@mock.com") |> delete_if_present()

      conn
      |> Systems.Account.UserAuth.sign_out_current_user()
      |> redirect(to: ~p"/user/auth/identify/mock")
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
