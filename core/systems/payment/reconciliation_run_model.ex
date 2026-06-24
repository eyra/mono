defmodule Systems.Payment.ReconciliationRunModel do
  @moduledoc """
  One row per reconciliation sweep, recording when it ran and the aggregate
  outcome tally. Lets us query reconciliation history without grepping logs.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Payment

  @run_types [:cron, :manual]

  schema "reconciliation_runs" do
    field(:run_type, Ecto.Enum, values: @run_types, default: :cron)
    field(:started_at, :naive_datetime)
    field(:finished_at, :naive_datetime)
    field(:scanned, :integer, default: 0)
    field(:resolved_completed, :integer, default: 0)
    field(:resolved_failed, :integer, default: 0)
    field(:still_pending, :integer, default: 0)
    field(:verified, :integer, default: 0)
    field(:missing_at_provider, :integer, default: 0)
    field(:unresolvable, :integer, default: 0)
    field(:errors, :integer, default: 0)
    field(:skipped, :integer, default: 0)

    has_many(:findings, Payment.ReconciliationFindingModel, foreign_key: :reconciliation_run_id)

    timestamps()
  end

  def run_types, do: @run_types

  @counters ~w(scanned resolved_completed resolved_failed still_pending verified
               missing_at_provider unresolvable errors skipped)a
  @fields ~w(run_type started_at finished_at)a ++ @counters

  def changeset(run, attrs) do
    run
    |> cast(attrs, @fields)
    |> validate_required([:run_type, :started_at])
  end
end
