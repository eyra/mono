defmodule Systems.Assignment.ActivateAccountViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  def view_model(%Account.User{email: email}, _assigns) do
    %{
      title: dgettext("eyra-assignment", "activate_account.title"),
      body:
        dgettext("eyra-assignment", "activate_account.body",
          email: ~s(<span class="text-primary">#{email}</span>)
        ),
      resend_button: resend_button(),
      check_button: check_button()
    }
  end

  defp resend_button do
    %{
      action: %{type: :send, event: "resend"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-assignment", "activate_account.resend.button")
      }
    }
  end

  defp check_button do
    %{
      action: %{type: :send, event: "check_confirmed"},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "activate_account.check.button")
      }
    }
  end
end
