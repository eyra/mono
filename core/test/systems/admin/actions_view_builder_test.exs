defmodule Systems.Admin.ActionsViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Admin.ActionsViewBuilder

  describe "view_model/2" do
    test "builds correct view model structure" do
      vm = ActionsViewBuilder.view_model(nil, %{})

      assert vm.title == dgettext("eyra-admin", "actions.title")
      assert is_list(vm.sections)
      assert length(vm.sections) == 3
    end

    test "builds bookkeeping section with rollback button" do
      vm = ActionsViewBuilder.view_model(nil, %{})

      bookkeeping_section = Enum.at(vm.sections, 0)
      assert bookkeeping_section.title == "Book keeping & Finance"
      assert length(bookkeeping_section.buttons) == 1

      button = hd(bookkeeping_section.buttons)
      assert button.action.type == :send
      assert button.action.event == "rollback_expired_deposits"
      assert button.face.type == :primary
      assert button.face.label == "Rollback expired deposits"
    end

    test "builds assignments section with expire button" do
      vm = ActionsViewBuilder.view_model(nil, %{})

      assignments_section = Enum.at(vm.sections, 1)
      assert assignments_section.title == "Assignments"
      assert length(assignments_section.buttons) == 1

      button = hd(assignments_section.buttons)
      assert button.action.type == :send
      assert button.action.event == "expire"
      assert button.face.type == :primary
      assert button.face.label == "Mark expired tasks"
    end

    test "builds monitoring section with crash button" do
      vm = ActionsViewBuilder.view_model(nil, %{})

      monitoring_section = Enum.at(vm.sections, 2)
      assert monitoring_section.title == "Monitoring"
      assert length(monitoring_section.buttons) == 1

      button = hd(monitoring_section.buttons)
      assert button.action.type == :send
      assert button.action.event == "crash"
      assert button.face.type == :primary
      assert button.face.bg_color == "bg-delete"
      assert button.face.label == "Raise a test exception"
    end
  end

  describe "build_expire_force_button/0" do
    test "builds expire force button for debug mode" do
      button = ActionsViewBuilder.build_expire_force_button()

      assert button.action.type == :send
      assert button.action.event == "expire_force"
      assert button.face.type == :primary
      assert button.face.bg_color == "bg-delete"
      assert button.face.label == "Mark all pending tasks expired"
    end
  end
end
