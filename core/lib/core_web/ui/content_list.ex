defmodule CoreWeb.UI.ContentList do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.ContentListItem

  prop(items, :list, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <ContentListItem :for={{item <- @items}} vm={{item}} />
    </div>
    """
  end
end
