defmodule Systems.Account.Public do
  use Core, :public
  use CoreWeb.StartPageProvider
  require Logger

  import Ecto.Query
  import Systems.Account.Queries
  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal

  alias Systems.Account
  alias Systems.Account.User
  alias Systems.Affiliate

  def create_profile!(user_id) do
    %Account.UserProfileModel{user_id: user_id}
    |> Repo.insert!()
  end

  def get!(id, preload \\ []) do
    user_query(id)
    |> Repo.one!()
    |> Repo.preload(preload)
  end

  def get_profile(%User{id: user_id}) do
    get_profile(user_id)
  end

  def get_profile(user_id) do
    if !is_nil(user_id) do
      Repo.get_by(Account.UserProfileModel, user_id: user_id) || create_profile!(user_id)
    end
  end

  def get_display_label(%User{} = user) do
    user_profile = get_profile(user)

    cond do
      user.displayname != nil -> user.displayname
      user_profile.fullname != nil -> user_profile.fullname
      true -> user.email
    end
  end

  def get_display_label(user_id) when is_integer(user_id) do
    get_user!(user_id)
    |> get_display_label()
  end

  def list_users(preload \\ []) do
    user_query()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_affiliate_users(preload \\ []) do
    user_query(affiliate?: true)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_external_users(preload \\ []) do
    user_query(external?: true)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_internal_users(preload \\ []) do
    user_query(internal?: true)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_creators(preload \\ []) do
    user_query(creator?: true)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_pool_admins(_preload \\ []) do
    Logger.error("FIXME: list_pool_admins")
    []
  end

  def search(query, preload \\ []) do
    user_query_by_email("%#{query}%")
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def update_user(user_changeset) do
    Multi.new()
    |> Multi.update(:user, user_changeset)
    |> Repo.transaction()
  end

  def update_user_profile(user_changeset, profile_changeset) do
    Multi.new()
    |> Multi.update(:profile, profile_changeset)
    |> Multi.update(:user, user_changeset)
    |> Signal.Public.multi_dispatch({:user_profile, :updated}, %{
      user_changeset: user_changeset,
      profile_changeset: profile_changeset
    })
    |> Repo.transaction()
  end

  ## Affiliate

  def affiliate?(%User{id: user_id}) do
    affiliate?(user_id)
  end

  def affiliate?(nil), do: false

  def affiliate?(user_id) do
    from(au in Affiliate.User,
      where: au.user_id == ^user_id
    )
    |> Repo.exists?()
  end

  # Deprecated. ExternalSignIn.User is replaced by Affiliate.User

  def external?(%User{id: user_id}) do
    external?(user_id)
  end

  def external?(nil), do: false

  def external?(user_id) do
    from(ex in ExternalSignIn.User,
      where: ex.user_id == ^user_id
    )
    |> Repo.exists?()
  end

  # Internal users are not affiliate users and not external users
  def internal?(%User{id: user_id}) do
    internal?(user_id)
  end

  def internal?(nil), do: false

  def internal?(user_id) do
    external? = external?(user_id)
    affiliate? = affiliate?(user_id)

    not (external? or affiliate?)
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    if user =
         from(u in User, where: u.email == ^email and not is_nil(u.confirmed_at)) |> Repo.one() do
      User.valid_password?(user, password) && user
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, preload \\ []) do
    from(user in User, preload: ^preload)
    |> Repo.get!(id)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- Account.UserTokenModel.verify_change_email_token_query(token, context),
         %Account.UserTokenModel{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      Account.UserTokenModel.user_and_contexts_query(user, [context])
    )
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &url(conn, ~p"/user/update-email/\#{&1}"
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} =
      Account.UserTokenModel.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)

    Account.UserNotifier.deliver_update_email_instructions(
      user,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, Account.UserTokenModel.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = Account.UserTokenModel.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = Account.UserTokenModel.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(Account.UserTokenModel.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(conn, ~p"/user/settings/confirm-email/\#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(conn, ~p"/user/settings/confirm-email/\#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = Account.UserTokenModel.build_email_token(user, "confirm")
      Repo.insert!(user_token)

      Account.UserNotifier.deliver_confirmation_instructions(
        user,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  def deliver_already_activated_notification(%User{} = user, login_url) do
    Account.UserNotifier.deliver_already_activated_notification(user, login_url)
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- Account.UserTokenModel.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(
      :tokens,
      Account.UserTokenModel.user_and_contexts_query(user, ["confirm"])
    )
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(conn, ~p"/user/reset-password/\#{&1}))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = Account.UserTokenModel.build_email_token(user, "reset_password")
    Repo.insert!(user_token)

    Account.UserNotifier.deliver_reset_password_instructions(
      user,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- Account.UserTokenModel.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, Account.UserTokenModel.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  # User Features

  def get_features(%User{id: user_id}) do
    get_features(user_id)
  end

  def get_features(user_id) do
    if !is_nil(user_id) do
      Repo.get_by(Account.FeaturesModel, user_id: user_id) || create_features!(user_id)
    end
  end

  defp create_features!(user_id) do
    %Account.FeaturesModel{user_id: user_id}
    |> Repo.insert!()
  end

  def update_features(%Account.FeaturesModel{} = features, changeset) do
    Multi.new()
    |> Repo.multi_update(:features, changeset)
    |> Signal.Public.multi_dispatch(:features_updated, %{
      features: features,
      features_changeset: changeset
    })
    |> Repo.transaction()
  end

  # Visited Pages

  def mark_as_visited(%User{visited_pages: nil} = user, page) when is_binary(page) do
    update_visited(user, [page])
  end

  def mark_as_visited(%User{visited_pages: visited_pages} = user, page) when is_binary(page) do
    if visited?(user, page) do
      Signal.Public.dispatch(:visited_pages_updated, %{user: user, visited_pages: visited_pages})
    else
      update_visited(user, visited_pages ++ [page])
    end
  end

  def mark_as_visited(user, page), do: mark_as_visited(user, page_key(page))

  defp update_visited(user, visited_pages) do
    changeset = user |> User.visited_changeset(%{visited_pages: visited_pages})

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Signal.Public.multi_dispatch(:visited_pages_updated, %{
      visited_pages: changeset.changes.visited_pages
    })
    |> Repo.transaction()
  end

  def visited?(%User{visited_pages: nil}, _page_key), do: false

  def visited?(%User{visited_pages: visited_pages}, page_key) when is_binary(page_key) do
    Enum.member?(visited_pages, page_key)
  end

  def visited?(user, page), do: visited?(user, page_key(page))

  defp page_key(page) when is_atom(page), do: Atom.to_string(page)
  defp page_key({page, id}) when is_atom(page) and is_integer(id), do: "#{page}_#{id}"
end

defimpl Core.Persister, for: Systems.Account.UserProfileEditModel do
  alias Systems.Account.UserProfileEditModel
  alias Systems.Account

  def save(%{user_id: user_id} = _user_profile_edit, %{changes: changes} = changeset) do
    user = Account.Public.get_user!(user_id)
    user_attrs = UserProfileEditModel.to_user(changes)
    user_changeset = Account.User.user_profile_changeset(user, user_attrs)

    profile = Account.Public.get_profile(user_id)
    profile_attrs = UserProfileEditModel.to_profile(changes)
    profile_changeset = Account.UserProfileModel.changeset(profile, profile_attrs)

    case Account.Public.update_user_profile(user_changeset, profile_changeset) do
      {:ok, %{user: user, profile: profile}} ->
        {:ok, UserProfileEditModel.create(user, profile)}

      _ ->
        {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Systems.Account.FeaturesModel do
  alias Systems.Account

  def save(features, changeset) do
    case Account.Public.update_features(features, changeset) do
      {:ok, %{features: features}} -> {:ok, features}
      _ -> {:error, changeset}
    end
  end
end
