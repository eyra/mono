defmodule Systems.DataDonation.TaskSpotStatusModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_task_spot_status" do
    field(:status, :string)
    belongs_to(:spot, DataDonation.SpotModel)
    belongs_to(:task, DataDonation.TaskModel)
  end

  @fields ~w(position title subtitle)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
