defmodule Systems.DataDonation.TaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    DataDonation
  }

  schema "data_donation_tasks" do
    field(:platform, :string)
    field(:position, :integer)
    field(:title, :string)
    field(:description, :string)

    belongs_to(:tool, DataDonation.ToolModel)
    has_many(:statuses, DataDonation.TaskSpotStatusModel, foreign_key: :task_id)

    belongs_to(:survey_task, DataDonation.SurveyTaskModel)
    belongs_to(:request_task, DataDonation.DocumentTaskModel)
    belongs_to(:download_task, DataDonation.DocumentTaskModel)
    belongs_to(:donate_task, DataDonation.DonateTaskModel)

    timestamps()
  end

  @fields ~w(position title description)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end
end
