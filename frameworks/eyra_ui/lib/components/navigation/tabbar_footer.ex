defmodule EyraUI.Navigation.TabbarFooter do
  @moduledoc false
  use Surface.Component

  alias EyraUI.Container.{ContentArea, FormArea}

  alias EyraUI.Button.Action.Click
  alias EyraUI.Button.Face.Forward

  slot(default)

  defp align(%{type: :sheet}), do: "justify-center"
  defp align(_), do: "justify-left"

  defp combine_shifted(tabs) do
    tabs |> Enum.chunk_every(2, 1, :discard)
  end

  def render(assigns) do
    ~H"""
    <ContentArea top_padding="pt-0">
      <FormArea>
        <Context get={{tabs: tabs}}>
          <div x-show="active_tab == {{ Enum.count(tabs)-1 }}" class="flex flex-row">
            <div class="flex-wrap">
              <slot />
            </div>
          </div>
          <div :for={{ {[tab1, tab2], index} <- Enum.with_index(combine_shifted(tabs)) }} x-show="active_tab == {{ index }}">
            <div x-show="active_tab < {{ Enum.count(tabs)-1 }}" class="flex flex-row {{ align(tab1) }}">
              <Click code="active_tab = active_tab + 1" >
                <Forward label="{{ tab2.forward_title }}" />
              </Click>
            </div>
          </div>
        </Context>
      </FormArea>
     </ContentArea>
    """
  end
end
