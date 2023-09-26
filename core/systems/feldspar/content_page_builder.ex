defmodule Systems.Feldspar.ContentPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Feldspar
  }

  def view_model(
        %Feldspar.ToolModel{id: id},
        _assigns
      ) do
    %{
      id: id,
      title: dgettext("eyra-feldspar", "content.title"),
      tabs: [],
      actions: [],
      show_errors: false
    }
  end
end
