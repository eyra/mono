defmodule Systems.Test.ModalLiveViewBuilder do
  alias Frameworks.Pixel.ModalButton
  alias Systems.Test

  def view_model(%Test.ModalModel{title: title, button_configs: button_configs}, _assigns) do
    %{
      title: title,
      buttons: build_buttons(button_configs)
    }
  end

  defp build_buttons(button_configs) when is_list(button_configs) do
    Enum.map(button_configs, fn config ->
      %ModalButton{
        label: config.label,
        icon: config.icon,
        icon_align: Map.get(config, :icon_align, :right),
        event: config.event,
        target: self()
      }
    end)
  end

  defp build_buttons(_), do: []
end
