defmodule CoreWeb.UI.Navigation.TabbarDropdown do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.TabbarItem
  alias Frameworks.Pixel.Line

  data(tabs, :any, from_context: :tabs)

  def render(assigns) do
    ~F"""
    <div>
      <Line />
      <div class="flex flex-col items-left p-6 gap-6 w-full bg-white drop-shadow-2xl">
        {#for {tab, index} <- Enum.with_index(@tabs)}
          <div class="flex-shrink-0">
            <TabbarItem tabbar="dropdown" vm={Map.put(tab, :index, index)} />
          </div>
        {/for}
      </div>
      <Line />
      <div class="h-5 bg-gradient-to-b from-black opacity-shadow">
      </div>
    </div>
    """
  end
end
