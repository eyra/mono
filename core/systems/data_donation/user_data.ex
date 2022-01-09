defmodule Systems.DataDonation.UserData do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  alias Systems.{
    DataDonation
  }

  schema "data_donation_user_data" do
    field(:data, :binary)
    belongs_to(:tool, DataDonation.ToolModel)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(user_data, attrs) do
    user_data
    |> cast(attrs, [:data])
    |> put_assoc(:tool, attrs[:tool])
    |> put_assoc(:user, attrs[:user])
    |> validate_required([:data])
  end
end
