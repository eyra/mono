defmodule Systems.Pool.SubmissionModel do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Frameworks.Utility.Schema
  use Frameworks.Utility.Model

  import Ecto.Changeset

  alias Systems.{
    Pool
  }

  alias CoreWeb.UI.Timestamp

  schema "pool_submissions" do
    field(:status, Ecto.Enum, values: Pool.SubmissionStatus.values())
    field(:reward_value, :integer, default: 0)
    field(:schedule_start, :string)
    field(:schedule_end, :string)

    field(:submitted_at, :naive_datetime)
    field(:accepted_at, :naive_datetime)
    field(:completed_at, :naive_datetime)

    has_one(:criteria, Pool.CriteriaModel, foreign_key: :submission_id)
    belongs_to(:pool, Pool.Model, on_replace: :update)

    timestamps()
  end

  def preload_graph(:pool), do: [pool: Pool.Model.preload_graph([:currency, :org, :auth_node])]

  @fields ~w(status reward_value schedule_start schedule_end submitted_at accepted_at completed_at)a

  @impl true
  def operational_fields, do: ~w(status reward_value)a

  @impl true
  def operational_validation(changeset) do
    changeset
    |> validate_schedule(:schedule_start, :schedule_end)
    |> Map.put(:action, :operational_validation)
  end

  defp validate_schedule(changeset, start_field, end_field) do
    start_date =
      get_field(changeset, start_field)
      |> Timestamp.parse_user_input_date()

    end_date =
      get_field(changeset, end_field)
      |> Timestamp.parse_user_input_date()

    case {start_date, end_date} do
      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {start_date, end_date} ->
        if Timestamp.after?(start_date, end_date) do
          add_error(changeset, end_field, "deadline is before start")
        else
          changeset
        end
    end
  end

  def changeset(submission, pool_id) when is_integer(pool_id) do
    submission
    |> cast(%{pool_id: pool_id}, [:pool_id])
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, @fields)
  end

  def schedule_ended?(%{schedule_end: schedule_end}) do
    past?(schedule_end)
  end

  def scheduled?(%{schedule_start: schedule_start}) do
    future?(schedule_start)
  end

  def concept?(%{submitted_at: submitted_at}), do: submitted_at == nil

  def status(%{status: status}), do: status
  def status(_), do: :idle

  def submitted?(%{submitted_at: submitted_at, status: status}),
    do: submitted_at != nil and status != :idle

  def submitted?(_), do: false

  def completed?(%{completed_at: completed_at}), do: completed_at != nil
  def completed?(_), do: false

  defp past?(nil), do: false

  defp past?(schedule_end) do
    Timestamp.parse_user_input_date(schedule_end)
    # add one day to include the end date
    |> Timex.shift(days: 1)
    |> Timestamp.past?()
  end

  defp future?(nil), do: false

  defp future?(schedule_start) do
    Timestamp.future?(schedule_start)
  end
end

defimpl Core.Persister, for: Systems.Pool.SubmissionModel do
  alias Systems.Pool

  def save(submission, changeset) do
    case Pool.Public.update(submission, changeset) do
      {:ok, %{submission: submission}} -> {:ok, submission}
      _ -> {:error, changeset}
    end
  end
end
