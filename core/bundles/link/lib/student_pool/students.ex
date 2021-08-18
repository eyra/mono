defmodule Link.StudentPool.Students do
  use Surface.LiveComponent

  import CoreWeb.Gettext

  alias CoreWeb.Empty
  alias EyraUI.Container.ContentArea

  prop(user, :any, required: true)

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Empty
          title={{ dgettext("link-studentpool", "students.empty.title") }}
          body={{ dgettext("link-studentpool", "students.empty.description") }}
          illustration="members"
      />
      </ContentArea>
    """
  end
end
