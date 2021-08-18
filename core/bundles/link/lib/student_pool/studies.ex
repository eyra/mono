defmodule Link.StudentPool.Studies do
  use Surface.LiveComponent

  import CoreWeb.Gettext

  alias CoreWeb.Empty
  alias EyraUI.Container.ContentArea

  prop(user, :any, required: true)

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Empty
          title={{ dgettext("link-studentpool", "studies.empty.title") }}
          body={{ dgettext("link-studentpool", "studies.empty.description") }}
          illustration="items"
      />
      </ContentArea>
    """
  end
end
