defmodule EmailSignUp do
  @moduledoc """
  Email-first signup identity provider.

  Creates a provisional Account.User (no password, not confirmed) plus a
  satellite `EmailSignUp.UserModel` record with the UserCheck validation
  result. Mirrors the GoogleSignIn / SignInWithApple / SurfConext pattern.

  The satellite row persists as a historical breadcrumb even after the user
  activates their account via another identity provider or by setting a
  password.

  ## Usage

      case EmailSignUp.register("user@example.com") do
        {:ok, user} -> # Account.User created + satellite stored
        {:error, :already_registered} -> # email exists in users table
        {:error, :disposable} -> # rejected by policy
        {:error, :invalid_format} -> # not a valid email
      end
  """

  require Logger

  alias Systems.Account.User
  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.UserCheck
  alias Frameworks.Signal

  @doc """
  Registers a user via email-first signup.

  1. Validates email format
  2. Checks uniqueness (returns `{:error, :already_registered}` if taken)
  3. Calls UserCheck for validation (fails open on timeout/error)
  4. Applies rejection policy
  5. Creates Account.User + EmailSignUp.UserModel in a single transaction

  ## Options

    * `:policy` - rejection policy module (default: `EmailSignUp.DefaultRejectionPolicy`)
  """
  def register(email, opts \\ []) when is_binary(email) do
    policy = Keyword.get(opts, :policy, EmailSignUp.DefaultRejectionPolicy)

    with :ok <- validate_format(email),
         :ok <- check_uniqueness(email),
         {:ok, validation_attrs} <- validate_email(email, policy) do
      create_user_with_satellite(email, validation_attrs)
    end
  end

  @doc """
  Returns true if the user is currently in a provisional state:
  no real password set and not confirmed.
  """
  def provisional?(%User{confirmed_at: nil, hashed_password: hashed_password})
      when hashed_password in [nil, "no-password-set"],
      do: true

  def provisional?(%User{}), do: false

  @doc """
  Returns the EmailSignUp.UserModel satellite for a given user, or nil.
  """
  def get_by_user(%User{id: user_id}) do
    Repo.get_by(EmailSignUp.UserModel, user_id: user_id)
  end

  @doc """
  Hard-deletes the user. Cascade deletes the satellite row.
  Use for GDPR opt-out requests.
  """
  def opt_out(%User{} = user) do
    Repo.delete(user)
  end

  defp validate_format(email) do
    if User.valid_email?(email), do: :ok, else: {:error, :invalid_format}
  end

  defp check_uniqueness(email) do
    if Repo.get_by(User, email: email) do
      {:error, :already_registered}
    else
      :ok
    end
  end

  defp validate_email(email, policy) do
    case UserCheck.check_email(email) do
      {:ok, result} ->
        case policy.reject?(result) do
          :ok ->
            {:ok, validation_attrs(result)}

          {:error, _reason} = error ->
            error
        end

      {:error, reason} ->
        Logger.warning("[EmailSignUp] UserCheck failed (failing open): #{inspect(reason)}")
        {:ok, unvalidated_attrs()}
    end
  end

  defp validation_attrs(%UserCheck.ResultModel{raw: raw} = _result) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    %{validation_data: raw, validated_at: now}
  end

  defp unvalidated_attrs do
    %{validation_data: nil, validated_at: nil}
  end

  defp create_user_with_satellite(email, validation_attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    user_changeset =
      User.sso_changeset(%User{}, %{
        email: email,
        creator: false,
        verified_at: now
      })

    Multi.new()
    |> Multi.insert(:user, user_changeset)
    |> Multi.insert(:email_sign_up_user, fn %{user: user} ->
      %EmailSignUp.UserModel{user_id: user.id}
      |> EmailSignUp.UserModel.changeset(validation_attrs)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{user: user}} ->
        Signal.Public.dispatch!({:user, :created}, %{user: user})
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}

      {:error, :email_sign_up_user, changeset, _} ->
        {:error, changeset}
    end
  end
end
