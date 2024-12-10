defmodule Systems.Alliance.ContentPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Alliance
  }

  def view_model(
        %Alliance.ToolModel{id: id},
        _assigns
      ) do
    %{
      id: id,
      title: dgettext("eyra-alliance", "content.title"),
      active_menu_item: :projects,
      tabs: [],
      breadcrumbs: [],
      actions: [],
      show_errors: false
    }
  end
end
