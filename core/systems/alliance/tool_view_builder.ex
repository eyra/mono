defmodule Systems.Alliance.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  @doc """
  Builds view model for Alliance tool view.

  Alliance is an abstract concept of an external platform. It only knows
  about url, title, and description - all provided via LiveContext.

  ## Parameters
  - tool: The Alliance tool model (not used, url comes from context)
  - assigns: Contains title, description, and url from LiveContext
  """
  def view_model(_tool, %{title: title, description: description, url: url}) do
    %{
      title: title,
      description: description,
      url: url,
      button: build_button(url)
    }
  end

  defp build_button(url) do
    %{
      action: %{
        type: :http_get,
        to: url,
        target: "_blank",
        phx_event: "start_tool"
      },
      face: %{
        type: :primary,
        label: dgettext("eyra-alliance", "tool.button")
      }
    }
  end
end
