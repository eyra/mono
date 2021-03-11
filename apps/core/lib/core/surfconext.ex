defmodule Core.SurfConext do
  alias Core.Accounts.User
  alias Core.Repo
  import Ecto.Query, warn: false

  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(
          from(sc in Core.SurfConext.User, where: sc.sub == ^sub, select: sc.user_id)
        )
    )
    |> Repo.one()
  end

  def register_user(attrs) do
    sso_info = %{
      email: Map.get(attrs, "email"),
      displayname: Map.get(attrs, "preferred_username"),
      profile: %{
        fullname: Map.get(attrs, "preferred_username")
      }
    }

    user = User.sso_changeset(%User{}, sso_info)

    %Core.SurfConext.User{}
    |> Core.SurfConext.User.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  defmacro routes() do
    surfconext_config = Application.fetch_env!(:core, Core.SurfConext)

    quote bind_quoted: [surfconext_config: surfconext_config] do
      pipeline :surfconext_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Core.SurfConext do
        pipe_through([:surfconext_browser])
        get("/surfconext", AuthorizePlug, surfconext_config)
        get("/surfconext/auth", CallbackPlug, surfconext_config)
      end
    end
  end
end
