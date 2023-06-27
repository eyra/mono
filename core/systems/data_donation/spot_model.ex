defmodule Systems.DataDonation.SpotModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_spots" do
    belongs_to(:tool, DataDonation.ToolModel)
    belongs_to(:auth_node, Core.Authorization.Node)
    has_many(:statuses, DataDonation.TaskSpotStatusModel, foreign_key: :spot_id)

    timestamps()
  end

  @fields ~w(position title subtitle)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
