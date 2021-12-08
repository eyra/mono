defmodule Core.Pools.Submission do
  @moduledoc """
  A task (donate data) to be completed by a participant.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model

  import CoreWeb.Gettext
  import Ecto.Changeset

  alias Core.Pools.{Criteria, Pool}
  alias Systems.Promotion
  alias CoreWeb.UI.Timestamp

  schema "pool_submissions" do
    field(:status, Ecto.Enum, values: [:idle, :submitted, :accepted])
    field(:reward_value, :integer)
    field(:reward_currency, :string)
    field(:schedule_start, :string)
    field(:schedule_end, :string)

    has_one(:criteria, Criteria)
    belongs_to(:promotion, Promotion.Model)
    belongs_to(:pool, Pool)

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w(status reward_value schedule_start schedule_end)a

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

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
  end

  def published_status(submission) do
    if closed?(submission) do
      :closed
    else
      if scheduled?(submission) do
        :scheduled
      else
        :online
      end
    end
  end

  defp closed?(%{schedule_end: schedule_end}) do
    past?(schedule_end)
  end

  defp scheduled?(%{schedule_start: schedule_start}) do
    future?(schedule_start)
  end

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

  def get_tag(%{status: status} = submission) do
    case status do
      :idle ->
        %{text: dgettext("eyra-submission", "status.idle.label"), type: :tertiary}

      :submitted ->
        %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

      :accepted ->
        case published_status(submission) do
          :scheduled ->
            %{
              text: dgettext("eyra-submission", "status.accepted.scheduled.label"),
              type: :tertiary
            }

          :online ->
            %{text: dgettext("eyra-submission", "status.accepted.online.label"), type: :success}

          :closed ->
            %{text: dgettext("eyra-submission", "status.accepted.closed.label"), type: :disabled}
        end
    end
  end
end
