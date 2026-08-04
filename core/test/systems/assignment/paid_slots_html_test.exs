defmodule Systems.Assignment.PaidSlotsHtmlTest do
  @moduledoc """
  Rendering rules for the pay-in transaction cards on the participants tab.

  The "Proceed with payment" CTA may only appear while a pay-in is still in
  flight. Once OPP has ended the transaction — declined, cancelled or expired —
  it is terminal, and the researcher retries by starting a new pay-in (which
  mints a fresh idempotence key) rather than reopening the old one.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Systems.Assignment.PaidSlotsHtml

  @resume_button ~s(data-testid="resume-payment-button")

  describe "paid_slots/1 retry CTA" do
    test "renders the resume-payment CTA while the pay-in is pending" do
      assert render_card(:pending) =~ @resume_button
    end

    test "omits the resume-payment CTA once the pay-in has failed" do
      refute render_card(:failed) =~ @resume_button
    end

    test "omits the resume-payment CTA once the pay-in has completed" do
      refute render_card(:completed) =~ @resume_button
    end
  end

  describe "paid_slots/1 status card" do
    test "marks a failed pay-in with a terminal status card" do
      assert render_card(:failed) =~ ~s(data-testid="transaction-card-failed")
    end
  end

  defp render_card(status) do
    render_component(&PaidSlotsHtml.paid_slots/1, %{
      entity: %{subject_reward: 500},
      transactions: [pay_in(status)],
      add_button: add_button(),
      target: :stub
    })
  end

  defp pay_in(status) do
    %{
      status: status,
      transaction_id: "t_1",
      invoice_id: "NEXT-NL-0001",
      subject_count: 10,
      total_amount: 5000
    }
  end

  defp add_button do
    %{
      action: %{type: :send, event: "add_budget", target: :stub},
      face: %{type: :primary, label: "Add participants"},
      testid: "pay-add-participants-button"
    }
  end
end
