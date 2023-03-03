defmodule Systems.Budget.WalletList do
  use CoreWeb.UI.Component

  alias Systems.Budget.WalletListItem

  prop(items, :list, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-col gap-10">
      <WalletListItem :for={item <- @items} vm={item} />
    </div>
    """
  end
end
