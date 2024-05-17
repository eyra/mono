defmodule Systems.Alliance.ContentPageBuilder do
  import CoreWeb.Gettext

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
      actions: [],
      show_errors: false
    }
  end
end
