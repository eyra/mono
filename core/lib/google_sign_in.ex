defmodule GoogleSignIn do
  @moduledoc """
  Google identity provider. Implements `Core.Identity.Provider` — the
  orchestration of "find user by email, attach or refresh satellite"
  lives in `Core.Identity`.

  Whether a Google sign-in produces a researcher or a participant
  depends on the signup flow the user came from. The Google callback
  plug passes `%{creator: creator?}` as `register_overrides` to
  `Core.Identity.authenticate/3`; the orchestrator merges it on top of
  this module's `user_attrs/1` output when a brand-new Account.User
  is registered.
  """
  @behaviour Core.Identity.Provider

  alias Systems.Account.User
  alias Core.Repo
  import Ecto.Query, warn: false

  @impl Core.Identity.Provider
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

  @impl Core.Identity.Provider
  def get(%User{id: id}) do
    Repo.get_by(GoogleSignIn.User, user_id: id)
  end

  @impl Core.Identity.Provider
  def attach(%User{} = user, userinfo) when is_map(userinfo) do
    %GoogleSignIn.User{}
    |> GoogleSignIn.User.changeset(userinfo)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl Core.Identity.Provider
  def refresh(%User{} = user, userinfo) when is_map(userinfo) do
    get(user)
    |> GoogleSignIn.User.changeset(userinfo)
    |> Repo.update!()
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :google_sign_in_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", GoogleSignIn do
        pipe_through([:google_sign_in_browser])
        get("/auth/google", AuthorizePlug, otp_app, as: :google_sign_in)
      end

      scope "/", GoogleSignIn do
        pipe_through([:browser])
        get("/auth/google/callback", CallbackPlug, otp_app)
      end
    end
  end
end
