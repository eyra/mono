defmodule Systems.Affiliate.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Affiliate

  @fields ~w(identifier)a
  @required_fields @fields

  schema "affiliate_user" do
    field(:identifier, :string)

    belongs_to(:affiliate, Affiliate.Model)
    belongs_to(:user, Account.User)

    timestamps()
  end

  def changeset(%Affiliate.User{} = user, attrs) do
    cast(user, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint([:identifier, :affiliate_id], name: :affiliate_user_unique)
  end
end
