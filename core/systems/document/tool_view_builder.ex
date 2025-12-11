defmodule Systems.Document.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Document

  @doc """
  Builds view model for Document tool view.

  ## Parameters
  - tool: The Document tool model
  - assigns: Contains title from CrewTaskContext
  """
  def view_model(%{id: id, ref: ref}, %{title: title}) do
    %{
      title: title,
      pdf_view: build_pdf_view(id, ref),
      done_button: build_done_button()
    }
  end

  defp build_pdf_view(id, ref) do
    %{
      module: Document.PDFView,
      id: "pdf_view_#{id}",
      key: "pdf_view_#{id}",
      url: ref,
      visible: true
    }
  end

  defp build_done_button do
    %{
      action: %{type: :send, event: "done"},
      face: %{
        type: :primary,
        bg_color: "bg-success",
        label: dgettext("eyra-document", "ready.button")
      }
    }
  end
end
