defmodule SignInWithApple do
  alias Core.Accounts.User
  alias Core.Repo
  alias Frameworks.Signal
  import Ecto.Query, warn: false

  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(
          from(sc in SignInWithApple.User, where: sc.sub == ^sub, select: sc.user_id)
        )
    )
    |> Repo.one()
  end

  def register_user(attrs) do
    fullname =
      [attrs.first_name, attrs.middle_name, attrs.last_name]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    display_name = Map.get(attrs, "first_name", fullname)

    sso_info = %{
      email: attrs.email,
      displayname: display_name,
      profile: %{fullname: fullname}
    }

    user = User.sso_changeset(%User{}, sso_info)

    with {:ok, apple_user} <-
           %SignInWithApple.User{}
           |> SignInWithApple.User.changeset(attrs)
           |> Ecto.Changeset.put_assoc(:user, user)
           |> Repo.insert() do
      Signal.Public.dispatch!({:user, :created}, %{user: apple_user.user})
      {:ok, apple_user}
    end
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :sign_in_with_apple_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", SignInWithApple do
        pipe_through([:sign_in_with_apple_browser])
        post("/apple/auth", CallbackPlug, otp_app)
      end
    end
  end
end
