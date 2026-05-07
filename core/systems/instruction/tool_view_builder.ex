defmodule Systems.Instruction.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Content

  @doc """
  Builds view model for Instruction tool view.

  ## Parameters
  - tool: The Instruction tool model
  - assigns: Contains dependencies from CrewTaskContext (minimal for this tool)
  """
  def view_model(tool, _assigns) do
    page = get_first_page(tool)

    %{
      tool: tool,
      page: page,
      page_view: build_page_view(page),
      done_button: build_done_button()
    }
  end

  defp get_first_page(%{pages: [%{page: page} | _]}), do: page
  defp get_first_page(_), do: nil

  defp build_page_view(nil), do: nil

  defp build_page_view(page) do
    %{
      module: Content.PageView,
      id: :page_view,
      title: dgettext("eyra-instruction", "page.title"),
      page: page
    }
  end

  defp build_done_button do
    %{
      action: %{type: :send, event: "done"},
      face: %{type: :primary, label: dgettext("eyra-ui", "done.button")}
    }
  end
end
