defmodule CoreWeb.UI.PlainDialog do
  use CoreWeb, :ui

  import CoreWeb.UI.Popup
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

  attr(:dialog, :map, default: nil)

  def plain_dialog_block(assigns) do
    ~H"""
      <%= if @dialog do %>
        <.popup>
          <div class="flex-wrap mx-6 sm:mx-10 p-8 bg-white shadow-floating rounded">
            <.plain_dialog {@dialog} />
          </div>
        </.popup>
      <% end %>
    """
  end
end
