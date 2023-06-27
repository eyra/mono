defmodule Systems.DataDonation.TaskModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

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

  @fields ~w(platform position title description)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :survey_task,
        :request_task,
        :download_task,
        :donate_task
      ])

  def preload_graph(:survey_task), do: [survey_task: []]
  def preload_graph(:request_task), do: [request_task: []]
  def preload_graph(:download_task), do: [download_task: []]
  def preload_graph(:donate_task), do: [donate_task: []]
end
