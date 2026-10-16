defmodule Systems.Fund.FundingPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(user, _assigns) do
    create_fund = %{
      state: :transparent,
      title: dgettext("eyra-fund", "funding.funds.new.title"),
      icon: {:static, "add_tertiary"},
      action: %{type: :send, event: "create_fund", item: "first", target: false}
    }

    edit_button = %{
      action: %{type: :send, event: "edit_fund", target: false},
      face: %{type: :label, label: dgettext("eyra-fund", "edit.button.label"), icon: :edit}
    }

    deposit_button = %{
      action: %{type: :send, event: "deposit_money", target: false},
      face: %{
        type: :label,
        label: dgettext("eyra-fund", "deposit.button.label"),
        icon: :deposit
      }
    }

    %{
      create_fund: create_fund,
      edit_button: edit_button,
      deposit_button: deposit_button,
      user: user,
      active_menu_item: :projects
    }
  end
end
