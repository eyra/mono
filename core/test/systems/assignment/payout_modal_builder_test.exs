defmodule Systems.Assignment.PayoutModalBuilderTest do
  use Core.DataCase

  alias Systems.Assignment
  alias Systems.Assignment.PayoutModalBuilder, as: Builder

  describe "resolve_tab/1" do
    test "resolves the waiting tab from its string" do
      assert Builder.resolve_tab("waiting") == :waiting
    end

    test "resolves the overview tab from its string" do
      assert Builder.resolve_tab("overview") == :overview
    end

    test "passes through known atoms" do
      assert Builder.resolve_tab(:overview) == :overview
    end

    test "falls back to :waiting on an unknown client value (no crash)" do
      assert Builder.resolve_tab("not-a-tab") == :waiting
    end

    test "falls back to :waiting on nil" do
      assert Builder.resolve_tab(nil) == :waiting
    end
  end

  describe "view_model/2" do
    setup do
      assignment = Assignment.Factories.create_assignment(31, 1)
      {:ok, assignment: assignment}
    end

    test "returns resolved labels (no dgettext in the view layer)", %{
      assignment: %{id: id}
    } do
      vm = Builder.view_model(id, %{})

      assert is_binary(vm.labels.tab_waiting)
      assert is_binary(vm.labels.pay_out_all_error)
      assert is_binary(vm.labels.decline_error)
    end

    test "defaults to the :waiting tab with no pending payouts", %{assignment: %{id: id}} do
      vm = Builder.view_model(id, %{})

      assert vm.active_tab == :waiting
      assert vm.payouts == []
      assert vm.count == 0
    end

    test "carries transient decline/error state through", %{assignment: %{id: id}} do
      vm = Builder.view_model(id, %{declining_task_id: 42, error: :decline})

      assert vm.declining_task_id == 42
      assert vm.error == :decline
    end
  end
end
