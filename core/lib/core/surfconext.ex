defmodule Core.SurfConext do
  @moduledoc """
  SURFconext identity provider. Implements `Core.Identity.Provider` —
  the orchestration of "find user by email, attach or refresh satellite"
  lives in `Core.Identity`.
  """
  @behaviour Core.Identity.Provider

  alias Systems.Account.User
  alias Core.Repo
  import Ecto.Query, warn: false

  require Logger

  defmodule SurfConextError do
    defexception [:message]
  end

  @impl Core.Identity.Provider
  def user_attrs(userinfo) when is_map(userinfo) do
    fullname =
      ~w(given_name family_name)
      |> Enum.map(&Map.get(userinfo, &1, ""))
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(" ")

    %{
      email: get_email(userinfo),
      displayname: Map.get(userinfo, "given_name", fullname),
      creator: true,
      confirmed_at: NaiveDateTime.utc_now(),
      fullname: fullname
    }
  end

  @impl Core.Identity.Provider
  def get(%User{id: id}) do
    Repo.get_by(Core.SurfConext.User, user_id: id)
  end

  @impl Core.Identity.Provider
  def attach(%User{} = user, userinfo) when is_map(userinfo) do
    %Core.SurfConext.User{}
    |> Core.SurfConext.User.register_changeset(satellite_attrs(userinfo))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl Core.Identity.Provider
  def refresh(%User{} = user, userinfo) when is_map(userinfo) do
    get(user)
    |> Core.SurfConext.User.update_changeset(%{userinfo: userinfo})
    |> Repo.update!()
  end

  defp satellite_attrs(userinfo) do
    %{
      email: get_email(userinfo),
      sub: Map.get(userinfo, "sub"),
      userinfo: userinfo
    }
  end

  defp get_email(userinfo) do
    case Map.get(userinfo, "email") do
      nil -> raise SurfConextError, "No email found in user info #{inspect(userinfo)}"
      email -> email
    end
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :surfconext_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Core.SurfConext do
        pipe_through([:surfconext_browser])
        get("/auth/surfconext", AuthorizePlug, otp_app)
      end

      scope "/", Core.SurfConext do
        pipe_through([:browser])
        get("/auth/surfconext/callback", CallbackController, :authenticate)
      end
    end
  end
end
