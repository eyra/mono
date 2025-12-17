defmodule Systems.Affiliate.Public do
  use Systems.Affiliate.Constants
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  require Logger

  import Ecto.Query, warn: true
  import Ecto.Changeset

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal

  alias Systems.Account
  alias Systems.Affiliate

  @resource_map %{
    Systems.Assignment.Model => @annotation_resource_id
    # add more types as needed
  }

  def send_event(nil, _event, _user), do: {:error, :affiliate_url_missing}
  def send_event(_affiliate, nil, _user), do: {:error, :event_missing}

  def send_event(_affiliate, event, _user) when not is_map(event),
    do: {:error, :event_invalid_format}

  def send_event(_affiliate, _event, nil), do: {:error, :user_missing}

  def send_event(affiliate, %{} = event, user) do
    case get_user(user) do
      {:ok, affiliate_user} ->
        Affiliate.Private.callback(affiliate, get_user_info(affiliate_user), event)

      {:error, :user_not_found} ->
        {:error, :user_not_found}
    end
  end

  def url_for_resource(%resource_type{} = %{id: id}) do
    path = ~p"/a/#{Affiliate.Sqids.encode!([@resource_map[resource_type], id])}"
    get_base_url() <> path
  end

  def decode_id(id) do
    Affiliate.Sqids.decode!(id)
  end

  def redirect_url(_affiliate, nil), do: {:error, :user_missing}

  def redirect_url(affiliate, %Account.User{} = user) do
    case get_user(user) do
      {:ok, affiliate_user} ->
        Affiliate.Private.redirect_url(affiliate, get_user_info(affiliate_user))

      error ->
        error
    end
  end

  def redirect_url(%{redirect_url: redirect_url}, %Affiliate.User{} = user) do
    Affiliate.Private.merge(redirect_url, get_user_info(user))
  end

  def prepare_affiliate(callback_url \\ nil, redirect_url \\ nil) do
    %Affiliate.Model{}
    |> Affiliate.Model.changeset(%{
      callback_url: callback_url,
      redirect_url: redirect_url
    })
  end

  def obtain_user_info!(%Affiliate.User{} = user, info) do
    {:ok, affiliate_user_info} = obtain_user_info(user, info)
    affiliate_user_info
  end

  def obtain_user_info(%Affiliate.User{} = user, info) do
    Multi.new()
    |> Multi.insert(
      :affiliate_user_info,
      prepare_user_info(user, info),
      on_conflict: {:replace, [:info]},
      conflict_target: [:user_id]
    )
    |> Signal.Public.multi_dispatch({:affiliate_user_info, :obtained})
    |> Repo.commit()
    |> case do
      {:ok, %{affiliate_user_info: affiliate_user_info}} ->
        {:ok, affiliate_user_info}

      error ->
        error
    end
  end

  def prepare_user_info(%Affiliate.User{} = user, info) do
    %Affiliate.UserInfoModel{}
    |> Affiliate.UserInfoModel.changeset(%{info: info})
    |> put_assoc(:user, user)
  end

  def obtain_user!(identifier, %Affiliate.Model{} = affiliate) do
    case obtain_user(identifier, affiliate) do
      {:ok, affiliate_user} ->
        affiliate_user

      error ->
        raise "Failed to obtain user: #{inspect(error)}"
    end
  end

  def obtain_user(identifier, %Affiliate.Model{} = affiliate) do
    Multi.new()
    |> Multi.run(:affiliate_user, fn _, _ ->
      case get_user(affiliate, identifier, [:user]) do
        nil ->
          register_user(identifier, affiliate)

        user ->
          {:ok, user}
      end
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{affiliate_user: affiliate_user}} ->
        {:ok, affiliate_user}

      error ->
        error
    end
  end

  def get_user(%Account.User{} = user) do
    user =
      from(au in Affiliate.User,
        where: au.user_id == ^user.id
      )
      |> Repo.one()
      |> Repo.preload([:user])

    if user do
      {:ok, user}
    else
      {:error, :user_not_found}
    end
  end

  def get_user(_affiliate, _identifier, preload \\ [])

  def get_user(_, nil, _preload), do: nil

  def get_user(%Affiliate.Model{id: affiliate_id}, identifier, preload) do
    from(au in Affiliate.User,
      where: au.identifier == ^identifier and au.affiliate_id == ^affiliate_id
    )
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def get_user_info(%Affiliate.User{} = user) do
    from(aui in Affiliate.UserInfoModel,
      where: aui.user_id == ^user.id
    )
    |> Repo.one()
  end

  def register_user!(organisation, external_id) do
    case register_user(organisation, external_id) do
      {:ok, affiliate_user} ->
        affiliate_user

      error ->
        raise "Failed to register user: #{inspect(error)}"
    end
  end

  defp register_user(identifier, affiliate) do
    Multi.new()
    |> Multi.run(:user_count, fn _, _ ->
      {:ok, count_users(affiliate)}
    end)
    |> Multi.insert(:user, fn %{user_count: user_count} ->
      prepare_user(affiliate, user_count + 1, identifier)
    end)
    |> Multi.insert(:affiliate_user, fn %{user: user} ->
      prepare_affiliate_user(affiliate, user, identifier)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{affiliate_user: affiliate_user}} ->
        {:ok, affiliate_user}

      error ->
        error
    end
  end

  def count_users(%Affiliate.Model{id: affiliate_id}) do
    from(au in Affiliate.User,
      where: au.affiliate_id == ^affiliate_id
    )
    |> Repo.aggregate(:count, :id)
  end

  def prepare_user(%Affiliate.Model{id: affiliate_id}, user_id, identifier) do
    email = "affiliate_#{affiliate_id}_user_#{user_id}@next.eyra.co"
    name = "Affiliate User #{identifier}"

    Account.User.sso_changeset(%Account.User{}, %{
      email: email,
      creator: false,
      displayname: name,
      profile: %{
        fullname: name
      }
    })
  end

  def prepare_affiliate_user(affiliate, user, identifier) do
    %Affiliate.User{}
    |> Affiliate.User.changeset(%{identifier: identifier})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:affiliate, affiliate)
  end

  def validate_url(url) do
    case :hackney.request(:head, url, [], "", []) do
      {:ok, status, _} ->
        {:ok, status}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_base_url do
    Application.get_env(:core, :base_url)
  end
end
