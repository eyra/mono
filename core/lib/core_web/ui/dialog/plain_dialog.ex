defmodule CoreWeb.UI.PlainDialog do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Dialog

  prop(title, :string, required: true)
  prop(text, :string, required: true)
  prop(buttons, :string, default: [])

  defmacro __using__(_opts) do
    quote do
      alias CoreWeb.UI.PlainDialog

      data(dialog, :any)

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

  def render(assigns) do
    ~F"""
      <Dialog title={@title} text={@text} buttons={@buttons}></Dialog>
    """
  end
end
