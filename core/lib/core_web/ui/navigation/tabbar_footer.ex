defmodule CoreWeb.UI.Navigation.TabbarFooter do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Container.RestrictedWidthArea
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
      <ContentArea>
        <MarginY id={{:page_top}} />
          <Context get={{tabs: tabs}}>
            <div :for={{ {[tab1, tab2], index} <- Enum.with_index(combine_shifted(tabs)) }} x-show="active_tab == {{ index }}">
              <RestrictedWidthArea type={{ tab1.type }}>
                <div x-show="active_tab < {{ Enum.count(tabs)-1 }}" class="flex flex-row {{ align(tab1) }}">
                  <Click vm={{ %{code: "active_tab = active_tab + 1"} }} >
                    <Forward vm={{ %{label: tab2.forward_title} }} />
                  </Click>
                </div>
              </RestrictedWidthArea>
            </div>
            <RestrictedWidthArea type={{ List.last(tabs).type }}>
              <div x-show="active_tab == {{ Enum.count(tabs)-1 }}" class="flex flex-row">
                <div class="flex-wrap">
                  <slot />
                </div>
              </div>
            </RestrictedWidthArea>
        </Context>
      </ContentArea>
    """
  end
end
