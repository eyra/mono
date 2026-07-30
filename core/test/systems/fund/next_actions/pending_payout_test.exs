defmodule Systems.Fund.NextActions.PendingPayoutTest do
  use ExUnit.Case, async: true

  alias Systems.Fund.NextActions.PendingPayout

  describe "to_view_model/2" do
    test "builds the full next-action view model contract" do
      vm = PendingPayout.to_view_model(1, %{"assignment_id" => 42})

      assert %{
               title: title,
               description: description,
               cta_label: cta_label,
               cta_action: %{type: :redirect, to: _}
             } = vm

      for text <- [title, description, cta_label] do
        assert is_binary(text)
        assert text != ""
      end
    end

    test "links to the assignment's participants tab with the payout modal open" do
      %{cta_action: %{to: to}} =
        PendingPayout.to_view_model(1, %{"assignment_id" => 42})

      assert to == "/assignment/42/content?tab=participants&modal=payout"
    end

    test "renders the same action regardless of how many rewards are pending" do
      one = PendingPayout.to_view_model(1, %{"assignment_id" => 42})
      many = PendingPayout.to_view_model(17, %{"assignment_id" => 42})

      assert one == many
    end

    test "requires an assignment_id: there is no payout page to link to without one" do
      assert_raise FunctionClauseError, fn ->
        PendingPayout.to_view_model(1, %{})
      end
    end
  end
end
