defmodule GoogleSignIn do
  alias Systems.Account.User
  alias Core.Repo
  alias Frameworks.Signal
  import Ecto.Query, warn: false

  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(from(sc in GoogleSignIn.User, where: sc.sub == ^sub, select: sc.user_id))
    )
    |> Repo.one()
  end

  def register_user(attrs) do
    fullname =
      ~w(given_name family_name)
      |> Enum.map(&Map.get(attrs, &1, ""))
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(" ")

    display_name = Map.get(attrs, "given_name", fullname)

    # See:
    # Apply temp: https://github.com/eyra/mono/issues/558
    # Revert: https://github.com/eyra/mono/issues/563

    sso_info = %{
      creator: true,
      email: Map.get(attrs, "email"),
      displayname: display_name,
      profile: %{
        fullname: fullname
      }
    }

    user = User.sso_changeset(%User{}, sso_info)

    with {:ok, google_user} <-
           %GoogleSignIn.User{}
           |> GoogleSignIn.User.changeset(attrs)
           |> Ecto.Changeset.put_assoc(:user, user)
           |> Repo.insert() do
      Signal.Public.dispatch!({:user, :created}, %{user: google_user.user})
      {:ok, google_user}
    end
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :google_sign_in_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", GoogleSignIn do
        pipe_through([:google_sign_in_browser])
        get("/google-sign-in", AuthorizePlug, otp_app, as: :google_sign_in)
        get("/google-sign-in/auth", CallbackPlug, otp_app)
      end
    end
  end
end
