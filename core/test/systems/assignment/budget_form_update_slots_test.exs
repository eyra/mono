defmodule Systems.Assignment.BudgetFormUpdateSlotsTest do
  @moduledoc """
  White-box coverage of `BudgetForm`'s `update_slots` event handler.

  Regression test for FX#10075185897 — editing the fee visually reset the
  "Number of participants" input to 0 while `subject_count` in the socket
  kept its old value. Root cause: `update_slots` only wrote the count into
  `subject_count` and never mirrored it back into `slots_changeset`, so any
  re-render (e.g. after `save_reward`) rehydrated the number input from a
  stale changeset that still held 0.
  """

  use Core.DataCase, async: false

  alias Systems.Assignment.BudgetForm

  defp build_socket(subject_count) do
    slots_changeset =
      {%{subject_count: subject_count}, %{subject_count: :integer}}
      |> Ecto.Changeset.change()

    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        slots_changeset: slots_changeset,
        subject_count: subject_count,
        reward_cents: 250,
        base_cents: 0,
        fee_cents: 0,
        total_cents: 0
      }
    }
  end

  test "update_slots writes the new count into slots_changeset" do
    {:noreply, socket} =
      BudgetForm.handle_event(
        "update_slots",
        %{"slots" => %{"subject_count" => "3"}},
        build_socket(0)
      )

    assert Ecto.Changeset.get_field(socket.assigns.slots_changeset, :subject_count) == 3
  end

  test "update_slots writes the new count into the subject_count assign" do
    {:noreply, socket} =
      BudgetForm.handle_event(
        "update_slots",
        %{"slots" => %{"subject_count" => "3"}},
        build_socket(0)
      )

    assert socket.assigns.subject_count == 3
  end
end
