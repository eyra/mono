defmodule SignInWithApple.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sign_in_with_apple_users" do
    belongs_to(:user, Link.Accounts.User)
    field(:email, :string)
    field(:is_private_email, :boolean)
    field(:sub, :string)
    field(:first_name, :string)
    field(:middle_name, :string)
    field(:last_name, :string)

    timestamps()
  end

  def changeset(%SignInWithApple.User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :sub,
      :first_name,
      :middle_name,
      :last_name,
      :is_private_email
    ])
    |> validate_required(:sub)
  end
end
