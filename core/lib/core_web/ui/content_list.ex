defmodule CoreWeb.UI.ContentList do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.ContentListItem

  prop(items, :list, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-col gap-10">
      <ContentListItem :for={{item, index} <- Enum.with_index(@items)}
        id={index}
        vm={item}
      />
    </div>
    """
  end
end
