defmodule CoreWeb.UI.Navigation.TabbarFooter do
  @moduledoc false
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Container.RestrictedWidthArea
  alias Frameworks.Pixel.Button.Face.Forward

  slot(default)

  defp align(%{type: :sheet}), do: "justify-center"
  defp align(_), do: "justify-left"

  defp combine_shifted(tabs) do
    tabs |> Enum.chunk_every(2, 1, [%{id: "fake_tab"}])
  end

  def render(assigns) do
    ~H"""
      <ContentArea class="mb-8">
        <MarginY id={{:page_top}} />
          <Context get={{tabs: tabs}}>
            <div :for={{ {[tab1, tab2], index} <- Enum.with_index(combine_shifted(tabs)) }} >
              <RestrictedWidthArea type={{ tab1.type }}>
                <div class="flex flex-row {{ align(tab1) }}">
                  <div id="tabbar-footer-item-{{ tab1.id }}" phx-hook="TabbarFooterItem" data-tab-id={{ tab1.id }} data-target-tab-id={{ tab2.id }} class="tabbar-footer-item cursor-pointer hidden">
                    <Case value={{ index < Enum.count(tabs)-1 }} >
                      <True>
                        <Forward vm={{ %{label: tab2.forward_title} }} />
                      </True>
                      <False>
                        <slot />
                      </False>
                    </Case>
                  </div>
                </div>
              </RestrictedWidthArea>
            </div>
        </Context>
      </ContentArea>
    """
  end
end
