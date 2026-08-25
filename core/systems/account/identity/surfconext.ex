defmodule Systems.Account.Identity.Surfconext do
  @moduledoc """
  SURFconext identity provider. Implements `Systems.Account.Identity.Provider` —
  the orchestration of "find user by email, attach or refresh satellite"
  lives in `Systems.Account.Identity`.
  """
  @behaviour Systems.Account.Identity.Provider

  alias Systems.Account.User
  alias Core.Repo
  import Ecto.Query, warn: false

  require Logger

  defmodule SurfconextError do
    defexception [:message]
  end

  @impl Systems.Account.Identity.Provider
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

  @impl Systems.Account.Identity.Provider
  def get(%User{id: id}) do
    Repo.get_by(Systems.Account.Identity.Surfconext.UserModel, user_id: id)
  end

  @impl Systems.Account.Identity.Provider
  def attach(%User{} = user, userinfo) when is_map(userinfo) do
    %Systems.Account.Identity.Surfconext.UserModel{}
    |> Systems.Account.Identity.Surfconext.UserModel.register_changeset(satellite_attrs(userinfo))
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @impl Systems.Account.Identity.Provider
  def refresh(%User{} = user, userinfo) when is_map(userinfo) do
    get(user)
    |> Systems.Account.Identity.Surfconext.UserModel.update_changeset(%{userinfo: userinfo})
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
      nil -> raise SurfconextError, "No email found in user info #{inspect(userinfo)}"
      email -> email
    end
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :surfconext_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Systems.Account.Identity.Surfconext do
        pipe_through([:surfconext_browser])
        get("/auth/surfconext", AuthorizePlug, otp_app)
      end

      scope "/", Systems.Account.Identity.Surfconext do
        pipe_through([:browser])
        get("/auth/surfconext/callback", CallbackController, :authenticate)
      end
    end
  end
end
