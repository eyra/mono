defmodule Link.StudentPool.Students do
  use CoreWeb.UI.LiveComponent

  prop(user, :any, required: true)

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Empty
          title={{ dgettext("link-studentpool", "students.empty.title") }}
          body={{ dgettext("link-studentpool", "students.empty.description") }}
          illustration="members"
      />
      </ContentArea>
    """
  end
end
