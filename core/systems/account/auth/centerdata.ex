defmodule Systems.Account.Auth.Centerdata do
  @moduledoc "Centerdata/LISS Panel identity provider."
  @behaviour Systems.Account.Auth.Provider

  alias Core.Repo
  alias Systems.Account.Auth.Centerdata.UserModel
  alias Systems.Account.User

  defmodule CenterdataError do
    defexception [:message]
  end

  @impl Systems.Account.Auth.Provider
  def user_attrs(%{"email" => email, "email_verified" => true}) when is_binary(email) do
    %{email: email, confirmed_at: NaiveDateTime.utc_now()}
  end

  def user_attrs(userinfo) do
    raise CenterdataError, "Centerdata did not provide a verified email: #{inspect(userinfo)}"
  end

  @impl Systems.Account.Auth.Provider
  def get(%User{id: id}), do: Repo.get_by(UserModel, user_id: id)

  @impl Systems.Account.Auth.Provider
  def attach(%User{} = user, userinfo) do
    %UserModel{}
    |> UserModel.changeset(userinfo)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl Systems.Account.Auth.Provider
  def refresh(%User{} = user, userinfo) do
    user
    |> get()
    |> UserModel.changeset(userinfo)
    |> Repo.update!()
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :centerdata_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Systems.Account.Auth.Centerdata do
        pipe_through([:centerdata_browser])
        get("/auth/centerdata", AuthorizePlug, otp_app)
      end

      scope "/", Systems.Account.Auth.Centerdata do
        pipe_through([:browser])
        get("/auth/centerdata/callback", CallbackController, :authenticate)
      end
    end
  end
end
