defmodule Systems.Account.User do
  @moduledoc """
  The User module encapsulates the changesets for creating and updating users.

  The logic for hashing passwords is also managed here. Bcrypt is used as
  adviced by OWASP:

  https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#password-hashing-algorithms
  """
  use Ecto.Schema
  import Ecto.Changeset

  def email_max_length, do: 160
  def email_format, do: ~r/^[^\s]+@[^\s]+$/

  @derive {Inspect, except: [:password, :hashed_password]}
  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:hashed_password, :string)
    field(:confirmed_at, :naive_datetime)
    field(:verified_at, :naive_datetime)
    field(:displayname, :string)
    field(:visited_pages, {:array, :string})
    field(:creator, :boolean)

    has_one(:profile, Systems.Account.UserProfileModel)
    has_one(:features, Systems.Account.FeaturesModel)

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          email: String.t() | nil,
          password: String.t() | nil,
          hashed_password: String.t() | nil,
          confirmed_at: NaiveDateTime.t() | nil,
          verified_at: NaiveDateTime.t() | nil,
          displayname: String.t() | nil,
          visited_pages: list(String.t()) | nil,
          creator: boolean() | nil,
          profile: Systems.Account.UserProfileModel.t() | Ecto.Association.NotLoaded.t() | nil,
          features: Systems.Account.FeaturesModel.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    # See:
    # Apply temp: https://github.com/eyra/mono/issues/558
    # Revert: https://github.com/eyra/mono/issues/563

    user
    |> cast(attrs, [:email, :password, :creator])
    |> validate_email()
    |> validate_password(opts)
  end

  @doc """
  User changeset for profile page
  """
  def user_profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:creator, :displayname])
  end

  def valid_email?(email) when is_binary(email) do
    String.length(email) <= email_max_length() and
      String.match?(email, email_format())
  end

  def valid_email?(nil), do: false

  def validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, email_format(), message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: email_max_length())
    |> unsafe_validate_unique(:email, Core.Repo)
    |> unique_constraint(:email)
  end

  def validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp validate_displayname(changeset), do: validate_required(changeset, [:display_name])

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def valid_email_changeset(email \\ nil) do
    %Systems.Account.User{}
    |> cast(%{email: email}, [:email])
    |> validate_required([:email])
    |> validate_format(:email, email_format(), message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: email_max_length())
  end

  def visited_changeset(user, attrs) do
    user
    |> cast(attrs, [:visited_pages])
    |> validate_required([:visited_pages])
  end

  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:creator, :verified_at, :confirmed_at])
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the display name.
  """
  def display_changeset(user, attrs) do
    user
    |> cast(attrs, [:displayname])
    |> validate_displayname()
  end

  @doc """
  A user changeset for use with Single Sign On systems. It implicitly trusts
  most data that it receives.
  """
  def sso_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :displayname, :creator, :verified_at])
    |> cast_assoc(:profile)
    |> put_change(:hashed_password, "no-password-set")
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def new_session_changeset(credentials) do
    %Systems.Account.User{}
    |> cast(credentials, [:email, :password])
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Systems.Account.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def get_gender(%{features: nil}), do: nil
  def get_gender(%{features: %{gender: gender}}), do: gender

  def label(%{profile: %{fullname: fullname}}) when is_binary(fullname) and fullname != "",
    do: fullname

  def label(%{displayname: displayname}) when is_binary(displayname) and displayname != "",
    do: displayname

  def label(%{email: nil}), do: "?"
  def label(%{email: email}), do: String.split(email, "@") |> List.first()

  def user_id(%{assigns: assigns}), do: user_id(assigns)
  def user_id(%{current_user: user}), do: user_id(user)
  def user_id(%{user_id: id}), do: id
  def user_id(%{user: user}), do: user_id(user)
  def user_id(%__MODULE__{id: id}), do: id
  def user_id(id) when is_integer(id), do: id

  def user_id(_), do: nil

  defimpl Core.Authentication.Subject do
    def name(%{profile: %{fullname: fullname}}) when is_binary(fullname) and fullname != "",
      do: fullname

    def name(%{displayname: displayname}) when is_binary(displayname) and displayname != "",
      do: displayname

    def name(%{email: nil}), do: "?"
    def name(%{email: email}), do: String.split(email, "@") |> List.first()
  end
end
