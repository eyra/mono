defmodule Link.StudentPool.Form.Studies do
  use CoreWeb.UI.LiveComponent

  prop(user, :any, required: true)

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Empty
          title={{ dgettext("link-studentpool", "studies.empty.title") }}
          body={{ dgettext("link-studentpool", "studies.empty.description") }}
          illustration="items"
      />
      </ContentArea>
    """
  end
end
