defmodule GoogleSignIn do
  alias Core.Accounts.User
  alias Core.Repo
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

    sso_info = %{
      email: Map.get(attrs, "email"),
      displayname: fullname,
      profile: %{
        fullname: fullname
      }
    }

    user = User.sso_changeset(%User{}, sso_info)

    %GoogleSignIn.User{}
    |> GoogleSignIn.User.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  defmacro routes() do
    google_sign_in_config = Application.fetch_env!(:core, GoogleSignIn)

    quote bind_quoted: [google_sign_in_config: google_sign_in_config] do
      pipeline :google_sign_in_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", GoogleSignIn do
        pipe_through([:google_sign_in_browser])
        get("/google-sign-in", AuthorizePlug, google_sign_in_config)
        get("/google-sign-in/auth", CallbackPlug, google_sign_in_config)
      end
    end
  end
end
