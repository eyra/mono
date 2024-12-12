defmodule Systems.Document.ContentPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Document
  }

  def view_model(
        %Document.ToolModel{id: id},
        _assigns
      ) do
    %{
      id: id,
      title: dgettext("eyra-document", "content.title"),
      active_menu_item: :projects,
      breadcrumbs: [],
      tabs: [],
      actions: [],
      show_errors: false
    }
  end
end
