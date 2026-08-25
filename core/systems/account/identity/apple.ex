defmodule Systems.Account.Identity.Apple do
  @behaviour Systems.Account.Identity.Provider

  alias Systems.Account.User
  alias Core.Repo
  alias Frameworks.Signal
  import Ecto.Query, warn: false

  @impl true
  def user_attrs(userinfo) do
    fullname =
      [userinfo["first_name"], userinfo["middle_name"], userinfo["last_name"]]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    %{
      email: userinfo["email"],
      displayname: fullname,
      fullname: fullname,
      verified_at: NaiveDateTime.utc_now()
    }
  end

  @impl true
  def get(%User{id: user_id}),
    do: Repo.get_by(Systems.Account.Identity.Apple.UserModel, user_id: user_id)

  @impl true
  def attach(%User{} = user, userinfo) do
    %Systems.Account.Identity.Apple.UserModel{}
    |> Systems.Account.Identity.Apple.UserModel.changeset(userinfo)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl true
  def refresh(user, userinfo) do
    user
    |> get()
    |> Systems.Account.Identity.Apple.UserModel.changeset(userinfo)
    |> Repo.update!()
  end

  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(
          from(sc in Systems.Account.Identity.Apple.UserModel,
            where: sc.sub == ^sub,
            select: sc.user_id
          )
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
      profile: %{fullname: fullname},
      verified_at: NaiveDateTime.utc_now()
    }

    user = User.sso_changeset(%User{}, sso_info)

    with {:ok, apple_user} <-
           %Systems.Account.Identity.Apple.UserModel{}
           |> Systems.Account.Identity.Apple.UserModel.changeset(attrs)
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

      scope "/", Systems.Account.Identity.Apple do
        pipe_through([:sign_in_with_apple_browser])
        post("/apple/auth", CallbackPlug, otp_app)
      end
    end
  end
end
