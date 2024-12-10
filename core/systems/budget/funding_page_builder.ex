defmodule Systems.Budget.FundingPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(user, _assigns) do
    create_budget = %{
      state: :transparent,
      title: dgettext("eyra-budget", "funding.budgets.new.title"),
      icon: {:static, "add_tertiary"},
      action: %{type: :send, event: "create_budget", item: "first", target: false}
    }

    edit_button = %{
      action: %{type: :send, event: "edit_budget", target: false},
      face: %{type: :label, label: dgettext("eyra-budget", "edit.button.label"), icon: :edit}
    }

    deposit_button = %{
      action: %{type: :send, event: "deposit_money", target: false},
      face: %{
        type: :label,
        label: dgettext("eyra-budget", "deposit.button.label"),
        icon: :deposit
      }
    }

    %{
      create_budget: create_budget,
      edit_button: edit_button,
      deposit_button: deposit_button,
      user: user,
      active_menu_item: :projects
    }
  end
end
