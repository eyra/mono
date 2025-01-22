defmodule Systems.Lab.ContentPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Lab
  }

  def view_model(
        %Lab.ToolModel{id: id},
        _assigns
      ) do
    %{
      id: id,
      title: dgettext("link-lab", "content.title"),
      active_menu_item: :projects,
      breadcrumbs: [],
      tabs: [],
      actions: [],
      show_errors: false
    }
  end
end
