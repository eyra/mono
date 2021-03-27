defmodule SignInWithApple do
  alias Core.Accounts.User
  alias Core.Repo
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

    sso_info = %{
      email: attrs.email,
      displayname: fullname,
      profile: %{fullname: fullname}
    }

    user = User.sso_changeset(%User{}, sso_info)

    %SignInWithApple.User{}
    |> SignInWithApple.User.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  defmacro routes(sign_in_with_apple_config) do
    quote bind_quoted: [sign_in_with_apple_config: sign_in_with_apple_config] do
      pipeline :sign_in_with_apple_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", SignInWithApple do
        pipe_through([:sign_in_with_apple_browser])
        post("/apple/auth", CallbackPlug, sign_in_with_apple_config)
      end
    end
  end
end
