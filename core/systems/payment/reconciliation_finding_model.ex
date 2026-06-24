defmodule Systems.Payment.ReconciliationFindingModel do
  @moduledoc """
  One row per non-trivial reconciliation outcome (anything that was resolved,
  could not be resolved, errored, or diverged from the provider). Trivial
  outcomes (`:still_pending`, `:verified`) are counted on the run but not stored
  here.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Payment

  @subject_types [:transaction, :payout]
  @outcomes [
    :resolved_completed,
    :resolved_failed,
    :missing_at_provider,
    :unresolvable,
    :errors,
    :skipped
  ]

  schema "reconciliation_findings" do
    field(:subject_type, Ecto.Enum, values: @subject_types)
    field(:subject_id, :integer)
    field(:provider_uid, :string)
    field(:local_status_before, :string)
    field(:provider_status, :string)
    field(:outcome, Ecto.Enum, values: @outcomes)
    field(:details, :map)

    belongs_to(:reconciliation_run, Payment.ReconciliationRunModel)

    timestamps(updated_at: false)
  end

  def outcomes, do: @outcomes

  @required ~w(reconciliation_run_id subject_type subject_id outcome)a
  @optional ~w(provider_uid local_status_before provider_status details)a

  def changeset(finding, attrs) do
    finding
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
