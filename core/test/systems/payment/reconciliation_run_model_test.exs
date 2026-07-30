defmodule Systems.Payment.ReconciliationRunModelTest do
  @moduledoc """
  One row per sweep. `Reconciliation.finish_run/2` writes a `ReconciliationSummary`
  straight into this changeset, so the counter fields must all be castable under
  the names the summary uses — a field that silently fails to cast would leave
  the reconciliation history reading zero.
  """
  use Core.DataCase, async: true

  alias Systems.Payment.ReconciliationRunModel, as: Run
  alias Systems.Payment.ReconciliationSummary, as: Summary

  @started_at ~N[2026-07-29 10:00:00]

  defp changeset(attrs), do: Run.changeset(%Run{}, attrs)

  describe "defaults" do
    test "a fresh run is a cron run" do
      assert %Run{run_type: :cron} = %Run{}
    end

    test "every counter starts at zero" do
      run = %Run{}

      for counter <- [:scanned | Summary.outcomes()] do
        assert Map.fetch!(run, counter) == 0
      end
    end
  end

  describe "run_types/0" do
    test "lists how a sweep can be triggered" do
      assert Run.run_types() == [:cron, :manual]
    end
  end

  describe "changeset/2 required fields" do
    test "accepts the attrs start_run/1 supplies" do
      assert changeset(%{run_type: :cron, started_at: @started_at}).valid?
    end

    test "falls back to the :cron default when no run_type is given" do
      changeset = changeset(%{started_at: @started_at})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :run_type) == :cron
    end

    test "rejects a run_type explicitly blanked out" do
      changeset = changeset(%{run_type: nil, started_at: @started_at})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).run_type
    end

    test "rejects a run without a started_at" do
      changeset = changeset(%{run_type: :cron})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).started_at
    end

    test "rejects a run_type outside the enum" do
      changeset = changeset(%{run_type: :bogus, started_at: @started_at})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).run_type
    end

    test "accepts a manual run" do
      assert changeset(%{run_type: :manual, started_at: @started_at}).valid?
    end
  end

  describe "changeset/2 counters" do
    test "casts every counter the summary carries" do
      summary = Enum.reduce(Summary.outcomes(), Summary.new(), &Summary.tally(&2, &1))

      changeset =
        Run.changeset(
          %Run{run_type: :cron, started_at: @started_at},
          Map.put(summary, :finished_at, ~N[2026-07-29 10:05:00])
        )

      assert changeset.valid?

      for outcome <- Summary.outcomes() do
        assert Ecto.Changeset.get_change(changeset, outcome) == 1
      end

      assert Ecto.Changeset.get_change(changeset, :scanned) == length(Summary.outcomes())
    end

    test "rejects a non-numeric counter instead of silently storing nil" do
      changeset = changeset(%{run_type: :cron, started_at: @started_at, scanned: "many"})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).scanned
    end
  end
end
