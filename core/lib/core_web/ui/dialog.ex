defmodule CoreWeb.UI.Dialog do
  use CoreWeb.UI.Component

  alias EyraUI.Button.DynamicButton

  defviewmodel(
    title: nil,
    text: nil,
    buttons: []
  )

  prop(vm, :string, required: true)

  defmacro __using__(_opts) do
    quote do
      alias CoreWeb.UI.Dialog

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
    ~H"""
      <div class="p-8 bg-white shadow-2xl w-dialog-width sm:w-dialog-width-sm rounded">
        <div class="flex flex-col gap-4 sm:gap-8">
          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            {{ title(@vm) }}
          </div>
          <div class="text-bodymedium font-body sm:text-bodylarge">
            {{ text(@vm) }}
          </div>
          <div class="flex flex-row gap-4">
            <DynamicButton :for={{ button <- buttons(@vm) }} vm={{ button }} />
          </div>
        </div>
      </div>
    """
  end
end
