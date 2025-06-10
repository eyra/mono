defmodule Systems.Affiliate.Public do
  import Ecto.Query, warn: true
  import Ecto.Changeset

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Affiliate
  alias Systems.Account

  def prepare_affiliate(callback_url \\ nil, redirect_url \\ nil) do
    %Affiliate.Model{}
    |> Affiliate.Model.changeset(%{callback_url: callback_url, redirect_url: redirect_url})
  end

  def obtain_user_info!(%Affiliate.Model{} = affiliate, %Affiliate.User{} = user, info) do
    {:ok, %{user_info: user_info}} = obtain_user_info(affiliate, user, info)
    user_info
  end

  def obtain_user_info(%Affiliate.Model{} = affiliate, %Affiliate.User{} = user, info) do
    Multi.new()
    |> Multi.insert(
      :affiliate_user_info,
      prepare_user_info(user, affiliate, info),
      on_conflict: {:replace, [:info]},
      conflict_target: [:user_id, :affiliate_id]
    )
    |> Signal.Public.multi_dispatch({:affiliate_user_info, :obtained})
    |> Repo.transaction()
  end

  def prepare_user_info(%Affiliate.User{} = user, %Affiliate.Model{} = affiliate, info) do
    %Affiliate.UserInfoModel{}
    |> Affiliate.UserInfoModel.changeset(%{info: info})
    |> put_assoc(:user, user)
    |> put_assoc(:affiliate, affiliate)
  end

  def obtain_user(identifier, %Affiliate.Model{} = affiliate) do
    user =
      if user = get_user_by_identifier(identifier) do
        user
      else
        register_user!(identifier, affiliate)
      end

    user
  end

  def get_user_by_identifier(nil), do: nil

  def get_user_by_identifier(identifier) do
    from(u in Affiliate.User,
      where: u.identifier == ^identifier
    )
    |> Repo.preload([:user])
    |> Repo.one()
  end

  def register_user!(organisation, external_id) do
    case register_user(organisation, external_id) do
      {:ok, user} -> user
      _ -> raise "Failed to register user"
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

    external_user =
      Affiliate.User.changeset(%Affiliate.User{}, %{
        identifier: identifier,
        affiliate: affiliate
      })

    external_user
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert!()
  end

  def validate_url(url) do
    case :hackney.request(:head, url, [], "", []) do
      {:ok, status, _} ->
        {:ok, status}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
