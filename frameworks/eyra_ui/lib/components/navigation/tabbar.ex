defmodule EyraUI.Navigation.Tabbar do
  @moduledoc false
  use Surface.LiveComponent

  alias EyraUI.Line
  alias EyraUI.Navigation.TabbarItem
  alias EyraUI.Alignment.HorizontalCenter
  alias EyraUI.Container.ContentArea

  def render(assigns) do
    ~H"""
    <div>
      <ContentArea top_padding="pt-0">
        <HorizontalCenter>
        <div class="flex flex-row items-center gap-10 flex-wrap h-navbar">
          <Context get={{tabs: tabs}}>
            <For each={{ {tab, index} <- Enum.with_index(tabs) }}>
              <div x-on:mousedown="active_tab = {{ index }}">
                <TabbarItem vm={{ Map.put(tab, :index, index) }} />
              </div>
            </For>
          </Context>
        </div>
        </HorizontalCenter>
      </ContentArea>
      <Line />
    </div>
    """
  end
end
