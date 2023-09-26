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

    belongs_to(:questionnaire_task, DataDonation.QuestionnaireTaskModel)
    belongs_to(:request_task, DataDonation.DocumentTaskModel)
    belongs_to(:download_task, DataDonation.DocumentTaskModel)
    belongs_to(:donate_task, DataDonation.DonateTaskModel)

    timestamps()
  end

  @fields ~w(platform position title description)a
  @required_fields @fields

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(%DataDonation.TaskModel{} = task) do
    changeset =
      changeset(task, %{})
      |> validate()

    changeset.valid?()
  end

  def ready?(list) when is_list(list) do
    if Enum.member?(list, false) do
      :incomplete
    else
      :ready
    end
  end

  def ready?(%DataDonation.QuestionnaireTaskModel{} = special),
    do: DataDonation.QuestionnaireTaskModel.ready?(special)

  def ready?(%DataDonation.DocumentTaskModel{} = special),
    do: DataDonation.DocumentTaskModel.ready?(special)

  def ready?(%DataDonation.DonateTaskModel{} = special),
    do: DataDonation.DonateTaskModel.ready?(special)

  def status(%DataDonation.TaskModel{} = task) do
    ready?([
      ready?(task),
      ready?(special(task))
    ])
  end

  defp special(%{questionnaire_task: %{id: _id} = special}), do: special
  defp special(%{request_task: %{id: _id} = special}), do: special
  defp special(%{download_task: %{id: _id} = special}), do: special
  defp special(%{donate_task: %{id: _id} = special}), do: special

  def preload_graph(:down),
    do:
      preload_graph([
        :questionnaire_task,
        :request_task,
        :download_task,
        :donate_task
      ])

  def preload_graph(:questionnaire_task), do: [questionnaire_task: []]
  def preload_graph(:request_task), do: [request_task: []]
  def preload_graph(:download_task), do: [download_task: []]
  def preload_graph(:donate_task), do: [donate_task: []]
end
