defmodule Systems.Affiliate.Public do
  use Systems.Affiliate.Constants
  use CoreWeb, :verified_routes

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

  def send_progress_event(nil, event, _user) do
    Logger.warning("No affiliate found for event: #{inspect(event)}")
  end

  def send_progress_event(%{affiliate: affiliate}, event, user) do
    send_progress_event(affiliate, event, user)
  end

  def send_progress_event(%{callback_url: nil}, _event, _user),
    do: {:error, :callback_url_missing}

  def send_progress_event(%{callback_url: ""}, _event, _user), do: {:error, :callback_url_missing}

  def send_progress_event(%{callback_url: callback_url}, %{} = event, user) do
    case get_user(user) do
      {:ok, affiliate_user} ->
        %{info: info} = get_user_info(affiliate_user)

        callback_url
        |> Affiliate.Private.merge(info, event)
        |> Affiliate.Private.callback()

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

  def redirect_url(%Affiliate.Model{redirect_url: nil}, _user), do: nil
  def redirect_url(%Affiliate.Model{redirect_url: ""}, _user), do: nil

  def redirect_url(%Affiliate.Model{} = affiliate, %Account.User{} = user) do
    case get_user(user) do
      {:ok, affiliate_user} ->
        redirect_url(affiliate, affiliate_user)

      {:error, :user_not_found} ->
        nil
    end
  end

  def redirect_url(%Affiliate.Model{redirect_url: redirect_url}, %Affiliate.User{} = user) do
    %{info: info} = get_user_info(user)
    Affiliate.Private.merge(redirect_url, info)
  end

  def prepare_affiliate(callback_url \\ nil, redirect_url \\ nil) do
    %Affiliate.Model{}
    |> Affiliate.Model.changeset(%{callback_url: callback_url, redirect_url: redirect_url})
  end

  def obtain_user_info!(%Affiliate.User{} = user, info) do
    {:ok, %{affiliate_user_info: affiliate_user_info}} = obtain_user_info(user, info)
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
    |> Repo.transaction()
  end

  def prepare_user_info(%Affiliate.User{} = user, info) do
    %Affiliate.UserInfoModel{}
    |> Affiliate.UserInfoModel.changeset(%{info: info})
    |> put_assoc(:user, user)
  end

  def obtain_user(identifier, %Affiliate.Model{} = affiliate) do
    user =
      if user = get_user_by_identifier(identifier, [:user]) do
        user
      else
        register_user!(identifier, affiliate)
      end

    user
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

  def get_user_by_identifier(_identifier, preload \\ [])

  def get_user_by_identifier(nil, _preload), do: nil

  def get_user_by_identifier(identifier, preload) do
    from(au in Affiliate.User,
      where: au.identifier == ^identifier
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
      {:ok, user} ->
        user

      _ ->
        raise "Failed to register user"
    end
  end

  def register_user(organisation, external_id) when is_atom(organisation) do
    register_user(Atom.to_string(organisation), external_id)
  end

  def register_user(identifier, %Affiliate.Model{id: affiliate_id} = affiliate)
      when is_binary(identifier) do
    email = "affiliate+#{affiliate_id}_user_#{identifier}@next.eyra.co"
    name = "Affiliate User #{identifier}"

    user =
      Account.User.sso_changeset(%Account.User{}, %{
        email: email,
        creator: false,
        displayname: name,
        profile: %{
          fullname: name
        }
      })

    %Affiliate.User{}
    |> Affiliate.User.changeset(%{identifier: identifier})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:affiliate, affiliate)
    |> Repo.insert()
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
