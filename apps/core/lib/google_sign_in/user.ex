defmodule GoogleSignIn.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "google_sign_in_users" do
    belongs_to(:user, Core.Accounts.User)
    field(:sub, :string)
    field(:name, :string)
    field(:email, :string)
    field(:email_verified, :boolean)
    field(:given_name, :string)
    field(:family_name, :string)
    field(:picture, :string)
    field(:locale, :string)

    timestamps()
  end

  def changeset(%GoogleSignIn.User{} = user, attrs) do
    user
    |> cast(attrs, [
      :sub,
      :name,
      :email,
      :email_verified,
      :given_name,
      :family_name,
      :picture,
      :locale
    ])
    |> validate_required(:sub)
  end
end
