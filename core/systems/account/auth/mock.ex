defmodule Systems.Account.Auth.Mock do
  @behaviour Systems.Account.Auth.Provider

  alias Systems.Account.Auth.Methods

  def configured?, do: Methods.provider?(:mock)

  def valid_email?(email), do: is_binary(email) and String.ends_with?(email, "@mock.com")

  @impl true
  def user_attrs(%{"email" => email}),
    do: %{email: email, creator: true, verified_at: NaiveDateTime.utc_now()}

  defmodule UserModel do
    defstruct [:user_id]
  end

  @impl true
  def get(_user), do: nil

  @impl true
  def attach(user, _userinfo), do: {:ok, %UserModel{user_id: user.id}}

  @impl true
  def refresh(user, _userinfo), do: %UserModel{user_id: user.id}
end

defmodule Systems.Account.Auth.Mock.InitiatorPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if Systems.Account.Auth.Mock.configured?() do
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

defmodule Systems.Account.Auth.Mock.CallbackController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Plug.Conn

  alias Core.Repo
  alias Systems.Account.User

  def authenticate(conn, params) do
    email = params["email"] || get_session(conn, :mock_auth_email) || "example@mock.com"

    if Systems.Account.Auth.Mock.configured?() and
         Systems.Account.Auth.Mock.valid_email?(email) do
      case Repo.get_by(User, email: email) do
        nil ->
          {:ok, %{user: user}} =
            Systems.Account.Auth.authenticate(Systems.Account.Auth.Mock, %{
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

defmodule Systems.Account.Auth.Mock.ResetController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Ecto.Query
  import Plug.Conn

  alias Core.Repo
  alias Systems.Account.FeaturesModel
  alias Systems.Account.User

  def reset(conn, _params) do
    if Systems.Account.Auth.Mock.configured?() do
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
