defmodule Systems.Assignment.BudgetFormConfirmTest do
  @moduledoc """
  White-box coverage of `BudgetForm`'s `confirm` event handler.

  Replaces the Playwright test "confirm button is disabled when reward is 0"
  (UC-OPP-01.SEC-05) from `test/e2e/fund_assignment.spec.ts`.

  The button's visible disabled state is driven by `confirm_enabled?/1` at
  render time (`enabled?={@confirm_enabled?}` on the Pixel button → no
  phx-click attribute → click is a no-op). Independently, the `confirm`
  handler clause is guarded by `when count > 0`; if a `confirm` event
  reaches the LV with `subject_count == 0` (manual phx-click, race, etc.)
  the catch-all clause must no-op rather than create a transaction.

  Per `test/features/CLAUDE.md` this is an edge case — belongs at the unit
  level, not in a Wallaby feature test.
  """

  use Core.DataCase, async: false

  alias Core.Repo
  alias Systems.Assignment.BudgetForm
  alias Systems.Budget

  test "confirm no-ops and creates no transaction when subject_count is 0" do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, subject_count: 0}}

    {:noreply, returned_socket} = BudgetForm.handle_event("confirm", %{}, socket)

    assert returned_socket == socket
    assert Repo.aggregate(Budget.TransactionModel, :count) == 0
  end
end
