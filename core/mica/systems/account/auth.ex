defmodule Systems.Account.Auth do
  import Ecto.Query

  @moduledoc """
  Orchestrates federated authentication against an external Identity
  Provider (IdP).

  An IdP — SURFconext, Google, … — proves the user owns an email address
  and hands back a payload of proprietary fields ("userinfo"). Each IdP
  is represented in code by a *provider module* that implements the
  `Systems.Account.Auth.Provider` behaviour. A provider owns:

    * the satellite Ecto schema for that IdP (a row per linked identity)
    * the IdP-specific shape of `userinfo`

  This module owns the flow that is identical across every IdP:

    1. Translate `userinfo` into a normalized Account.User attrs map via
       the provider's `user_attrs/1`.
    2. Locate (or create) the Eyra Account.User by `:email`.
    3. Attach a new satellite row if the user has none, or refresh the
       existing one.

  Plugs/controllers call `authenticate/2` and react to the
  `{:ok, %{user: ..., first_time?: ...}}` result.
  """

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Account
  alias Systems.Account.Auth.Methods
  alias Systems.Account.User

  @typedoc "Normalized Account.User attrs returned by `c:Provider.user_attrs/1`."
  @type user_attrs :: %{required(:email) => String.t(), optional(atom()) => any()}

  @typedoc "Result of a successful federated authentication."
  @type result :: %{user: User.t(), first_time?: boolean()}

  @doc """
  Authenticate a federated sign-in.

  On success returns `{:ok, %{user: user, first_time?: bool}}`. The
  `first_time?` flag is `true` iff the Account.User was just created
  during this call; callers use it to choose between the
  post-registration landing (e.g. onboarding) and the regular
  post-signin destination.

  `register_overrides` is merged into the provider's `user_attrs/1`
  output before registering a brand-new Account.User. Used for
  situational data the IdP itself doesn't carry — for example, Google
  sign-in passes `%{creator: creator?}` because the same Google
  identity can be a researcher or a participant depending on which
  signup flow they came from. Has no effect when the user already
  exists.
  """
  @spec authenticate(
          provider :: module(),
          userinfo :: map(),
          register_overrides :: map()
        ) :: {:ok, result()} | {:error, Ecto.Changeset.t()}
  def authenticate(provider, userinfo, register_overrides \\ %{})
      when is_atom(provider) and is_map(userinfo) and is_map(register_overrides) do
    attrs = provider.user_attrs(userinfo) |> Map.merge(register_overrides)

    with {:ok, user, first_time?} <- find_or_register(attrs),
         {:ok, _satellite} <- upsert_satellite(provider, user, userinfo) do
      {:ok, %{user: user, first_time?: first_time?}}
    end
  end

  def authenticate_or_transfer(provider, userinfo, register_overrides \\ %{}) do
    email = provider.user_attrs(userinfo).email

    case Account.Public.get_user_by_email(email) do
      %User{} = user ->
        if is_nil(provider.get(user)) do
          {:transfer, user}
        else
          authenticate(provider, userinfo, register_overrides)
        end

      nil ->
        authenticate(provider, userinfo, register_overrides)
    end
  end

  def transfer(provider, satellite_key, %User{} = user, userinfo) do
    satellites =
      Methods.satellites()
      |> Map.values()

    selected_satellite = Methods.satellite(satellite_key)
    user_id = user.id

    Multi.new()
    |> Multi.run(:selected_identity, fn _repo, _changes ->
      upsert_satellite(provider, user, userinfo)
    end)
    |> Multi.run(:remove_other_identities, fn repo, _changes ->
      satellites
      |> Enum.reject(&(&1 == selected_satellite))
      |> Enum.each(fn satellite ->
        satellite
        |> Ecto.Queryable.to_query()
        |> where([s], s.user_id == ^user_id)
        |> repo.delete_all()
      end)

      {:ok, :removed}
    end)
    |> Repo.commit()
  end

  def remove_auth_methods(%User{} = user) do
    user_id = user.id

    Multi.new()
    |> Multi.run(:remove_identities, fn repo, _changes ->
      Methods.satellites()
      |> Map.values()
      |> Enum.each(fn satellite ->
        satellite
        |> Ecto.Queryable.to_query()
        |> where([s], s.user_id == ^user_id)
        |> repo.delete_all()
      end)

      {:ok, :removed}
    end)
    |> Repo.commit()
  end

  defp find_or_register(%{email: email} = attrs) do
    case Account.Public.get_user_by_email(email) do
      %User{} = existing ->
        {:ok, existing, false}

      nil ->
        with {:ok, user} <- Account.Public.register_via_sso(attrs) do
          {:ok, user, true}
        end
    end
  end

  defp upsert_satellite(provider, user, userinfo) do
    case provider.get(user) do
      nil -> provider.attach(user, userinfo)
      _existing -> {:ok, provider.refresh(user, userinfo)}
    end
  end
end
