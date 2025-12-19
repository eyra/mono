defmodule CoreWeb.Live.Hook.ContextTest do
  use CoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias CoreWeb.Live.Hook.Context
  alias Frameworks.Concept.LiveContext

  # Test view that declares dependencies
  defmodule TestViewWithDeps do
    use Phoenix.LiveView

    on_mount({Context, __MODULE__})

    def dependencies(), do: [:user_id, :title]

    @impl true
    def mount(:not_mounted_at_router, _session, socket) do
      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      assigns =
        assigns
        |> Map.put_new(:user_id, "missing")
        |> Map.put_new(:title, "missing")

      ~H"""
      <div data-testid="context-view">
        <span data-testid="user-id">{@user_id}</span>
        <span data-testid="title">{@title}</span>
      </div>
      """
    end
  end

  # Test view without dependencies
  defmodule TestViewNoDeps do
    use Phoenix.LiveView

    on_mount({Context, __MODULE__})

    @impl true
    def mount(:not_mounted_at_router, _session, socket) do
      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div data-testid="no-deps-view">No dependencies</div>
      """
    end
  end

  describe "context hook with all dependencies available" do
    test "extracts dependencies from context", %{conn: conn} do
      context = LiveContext.new(%{user_id: 123, title: "Test Title"})

      {:ok, view, html} =
        conn
        |> Map.put(:request_path, "/test")
        |> live_isolated(TestViewWithDeps, session: %{"live_context" => context})

      assert has_element?(view, "[data-testid='context-view']")
      assert html =~ "123"
      assert html =~ "Test Title"
    end
  end

  describe "context hook with missing dependencies" do
    test "still mounts view with default values when dependencies missing", %{conn: conn} do
      # Context only has user_id, missing title
      context = LiveContext.new(%{user_id: 123})

      {:ok, view, html} =
        conn
        |> Map.put(:request_path, "/test")
        |> live_isolated(TestViewWithDeps, session: %{"live_context" => context})

      # View should still mount (with missing assigns showing "missing")
      assert has_element?(view, "[data-testid='context-view']")

      # user_id should show "missing" because dependencies weren't extracted
      # (context wasn't ready, so no dependencies were assigned)
      assert html =~ "missing"
    end
  end

  describe "context hook without dependencies" do
    test "skips context extraction when no dependencies declared", %{conn: conn} do
      context = LiveContext.new(%{some_data: "value"})

      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "/test")
        |> live_isolated(TestViewNoDeps, session: %{"live_context" => context})

      assert has_element?(view, "[data-testid='no-deps-view']")
    end
  end

  describe "context hook without context in session" do
    test "mounts view without error when no context in session", %{conn: conn} do
      # When no context is in session, the hook should silently skip extraction
      # This is a common case for views that don't use context
      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "/test")
        |> live_isolated(TestViewWithDeps, session: %{})

      # View should still mount (with missing assigns showing "missing")
      assert has_element?(view, "[data-testid='context-view']")
    end
  end
end
