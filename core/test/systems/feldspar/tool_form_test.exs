defmodule Systems.Feldspar.ToolFormTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Systems.Feldspar

  # Wrapper that mounts two ToolForm components in the same LiveView.
  # Before the fix, this crashed: "existing upload for file already allowed
  # in another component" because both called allow_upload(:file).
  defmodule TwoToolFormsView do
    use Phoenix.LiveView

    def mount(_params, %{"tool1" => tool1, "tool2" => tool2}, socket) do
      {:ok, assign(socket, tool1: tool1, tool2: tool2)}
    end

    def render(assigns) do
      ~H"""
      <.live_component module={Feldspar.ToolForm} id="form_1" entity={@tool1} />
      <.live_component module={Feldspar.ToolForm} id="form_2" entity={@tool2} />
      """
    end
  end

  describe "multiple ToolForm components in the same LiveView" do
    test "two instances with different ids render without crashing", %{conn: conn} do
      tool1 = Factories.insert!(:feldspar_tool)
      tool2 = Factories.insert!(:feldspar_tool)
      conn = conn |> Map.put(:request_path, "/feldspar/tool_form")

      assert {:ok, _view, html} =
               live_isolated(conn, TwoToolFormsView,
                 session: %{"tool1" => tool1, "tool2" => tool2}
               )

      assert html =~ "form_1_file_selector_form"
      assert html =~ "form_2_file_selector_form"
    end

    test "each instance gets an upload key scoped to its id", %{conn: conn} do
      tool = Factories.insert!(:feldspar_tool)
      conn = conn |> Map.put(:request_path, "/feldspar/tool_form")

      # The file input name is derived from the upload key (file_<id>).
      # If the key were the global :file, the name would be "file" instead.
      assert {:ok, _view, html} =
               live_isolated(conn, TwoToolFormsView, session: %{"tool1" => tool, "tool2" => tool})

      assert html =~ "file_form_1"
      assert html =~ "file_form_2"
    end
  end
end
