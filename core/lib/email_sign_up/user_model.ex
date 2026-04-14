defmodule EmailSignUp.UserModel do
  @moduledoc """
  Satellite identity record for email-first signups.

  Mirrors the pattern of `GoogleSignIn.User`, `SignInWithApple.User`, etc.
  Stores the full UserCheck validation response as JSON at the time of
  registration. This record persists as a historical breadcrumb even after
  the user activates their account (sets a password, links Google, etc.).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_sign_up_user" do
    belongs_to(:user, Systems.Account.User)
    field(:validation_data, :map)
    field(:validated_at, :naive_datetime)
    timestamps()
  end

  def changeset(%__MODULE__{} = model, attrs) do
    model
    |> cast(attrs, [:validation_data, :validated_at])
    |> unique_constraint(:user_id, name: :email_sign_up_user_user_id_index)
  end
end
