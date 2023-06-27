defmodule CoreWeb.UI.PlainDialog do
  use CoreWeb, :html

  import CoreWeb.UI.Dialog

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.UI.PlainDialog

      # data(dialog, :any)

      defp confirm(socket, action, title, text, confirm_label) do
        buttons = [
          %{
            action: %{type: :send, event: "#{action}_confirm"},
            face: %{type: :primary, label: confirm_label}
          },
          %{
            action: %{type: :send, event: "#{action}_cancel"},
            face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
          }
        ]

        dialog = %{
          title: title,
          text: text,
          buttons: buttons
        }

        socket |> assign(dialog: dialog)
      end

      defp inform(socket, title, text) do
        buttons = [
          %{
            action: %{type: :send, event: "inform_ok"},
            face: %{type: :primary, label: dgettext("eyra-ui", "ok.button")}
          }
        ]

        dialog = %{
          title: title,
          text: text,
          buttons: buttons
        }

        socket |> assign(dialog: dialog)
      end
    end
  end

  attr(:title, :string, required: true)
  attr(:text, :string, required: true)
  attr(:buttons, :list, default: [])

  def plain_dialog(assigns) do
    ~H"""
    <.dialog title={@title} text={@text} buttons={@buttons} />
    """
  end
end
