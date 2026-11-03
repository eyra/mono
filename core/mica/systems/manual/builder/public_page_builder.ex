defmodule Systems.Manual.Builder.PublicPageBuilder do
  use Gettext, backend: MicaWeb.Gettext

  def view_model(_model, _assigns) do
    %{
      title: "Manual Builder"
    }
  end
end
