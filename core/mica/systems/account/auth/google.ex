defmodule Systems.Account.Auth.Google do
  @moduledoc """
  Google identity provider. Implements `Systems.Account.Auth.Provider` — the
  orchestration of "find user by email, attach or refresh satellite"
  lives in `Systems.Account.Auth`.

  Whether a Google sign-in produces a researcher or a participant
  depends on the signup flow the user came from. The Google callback
  plug passes `%{creator: creator?}` as `register_overrides` to
  `Systems.Account.Auth.authenticate/3`; the orchestrator merges it on top of
  this module's `user_attrs/1` output when a brand-new Account.User
  is registered.
  """
  @behaviour Systems.Account.Auth.Provider

  alias Systems.Account.User
  alias Core.Repo
  import Ecto.Query, warn: false

  @impl Systems.Account.Auth.Provider
  def user_attrs(userinfo) when is_map(userinfo) do
    fullname =
      ~w(given_name family_name)
      |> Enum.map(&Map.get(userinfo, &1, ""))
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(" ")

    %{
      email: Map.get(userinfo, "email"),
      displayname: Map.get(userinfo, "given_name", fullname),
      verified_at: NaiveDateTime.utc_now(),
      fullname: fullname
    }
  end

  @impl Systems.Account.Auth.Provider
  def get(%User{id: id}) do
    Repo.get_by(Systems.Account.Auth.Google.UserModel, user_id: id)
  end

  @impl Systems.Account.Auth.Provider
  def attach(%User{} = user, userinfo) when is_map(userinfo) do
    %Systems.Account.Auth.Google.UserModel{}
    |> Systems.Account.Auth.Google.UserModel.changeset(userinfo)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl Systems.Account.Auth.Provider
  def refresh(%User{} = user, userinfo) when is_map(userinfo) do
    get(user)
    |> Systems.Account.Auth.Google.UserModel.changeset(userinfo)
    |> Repo.update!()
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :google_sign_in_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Systems.Account.Auth.Google do
        pipe_through([:google_sign_in_browser])
        get("/auth/google", AuthorizePlug, otp_app, as: :google_sign_in)
      end

      scope "/", Systems.Account.Auth.Google do
        pipe_through([:browser])
        get("/auth/google/callback", CallbackPlug, otp_app)
      end
    end
  end
end
