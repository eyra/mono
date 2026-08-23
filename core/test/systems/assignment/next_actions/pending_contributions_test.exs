defmodule Systems.Assignment.NextActions.PendingContributionsTest do
  use Core.DataCase, async: true

  alias Systems.Assignment.NextActions.PendingContributions

  describe "to_view_model/2" do
    test "builds the full next-action view model contract" do
      vm = PendingContributions.to_view_model(1, %{"assignment_id" => 42})

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

    test "links to the assignment's Contributions tab" do
      %{cta_action: %{to: to}} = PendingContributions.to_view_model(1, %{"assignment_id" => 42})

      assert to == "/assignment/42/content?tab=contributions"
    end

    test "renders the same action regardless of how many contributions are pending" do
      one = PendingContributions.to_view_model(1, %{"assignment_id" => 42})
      many = PendingContributions.to_view_model(17, %{"assignment_id" => 42})

      assert one == many
    end

    test "requires an assignment_id: there is no Contributions page to link to without one" do
      assert_raise FunctionClauseError, fn ->
        PendingContributions.to_view_model(1, %{})
      end
    end
  end
end
