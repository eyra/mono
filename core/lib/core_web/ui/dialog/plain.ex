defmodule CoreWeb.UI.Dialog.Plain do
  use CoreWeb, :live_component
  use Gettext, backend: CoreWeb.Gettext

  import CoreWeb.UI.Dialog

  def update(%{type: type, title: title, text: text} = params, socket) do
    primary_button_label =
      params |> Map.get(:primary_button_label, dgettext("eyra-ui", "ok.button"))

    secondary_button_label =
      params |> Map.get(:secondary_button_label, dgettext("eyra-ui", "cancel.button"))

    {
      :ok,
      socket
      |> assign(
        type: type,
        title: title,
        text: text,
        primary_button_label: primary_button_label,
        secondary_button_label: secondary_button_label
      )
      |> update_buttons()
    }
  end

  defp update_buttons(
         %{
           assigns: %{
             type: :confirm,
             primary_button_label: primary_button_label,
             secondary_button_label: secondary_button_label
           }
         } = socket
       ) do
    buttons = [
      %{
        action: %{type: :send, event: "confirm_ok"},
        face: %{type: :primary, label: primary_button_label}
      },
      %{
        action: %{type: :send, event: "confirm_cancel"},
        face: %{type: :label, label: secondary_button_label}
      }
    ]

    socket |> assign(buttons: buttons)
  end

  defp update_buttons(
         %{assigns: %{type: :inform, primary_button_label: primary_button_label}} = socket
       ) do
    buttons = [
      %{
        action: %{type: :send, event: "inform_ok"},
        face: %{type: :primary, label: primary_button_label}
      }
    ]

    socket |> assign(buttons: buttons)
  end

  def render(assigns) do
    ~H"""
    <div>
      <.dialog title={@title} text={@text} buttons={@buttons} />
    </div>
    """
  end
end
