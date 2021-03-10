defmodule SurfConext do
  alias Link.Accounts.User
  alias Link.Repo
  import Ecto.Query, warn: false

  @spec get_user_by_sub(String.t()) :: none | Link.Accounts.User.t()
  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(from(sc in SurfConext.User, where: sc.sub == ^sub, select: sc.user_id))
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

    %SurfConext.User{}
    |> SurfConext.User.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  defmacro routes(surfconext_config) do
    quote bind_quoted: [surfconext_config: surfconext_config] do
      pipeline :surfconext_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", SurfConext do
        pipe_through([:surfconext_browser])
        get("/surfconext", AuthorizePlug, surfconext_config)
        get("/surfconext/auth", CallbackPlug, surfconext_config)
      end
    end
  end
end
