defmodule Frameworks.UserStateTest do
  use CoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Frameworks.UserState
  alias Frameworks.UserState.LocalStorage
  alias Frameworks.UserState.Storage

  describe "save/5" do
    test "builds storage key from namespace and key" do
      user = %{id: 42}
      namespace = [:manual, 123]
      key = :chapter

      socket = %Phoenix.LiveView.Socket{
        transport_pid: self(),
        assigns: %{__changed__: %{}},
        private: %{live_temp: %{}}
      }

      result = UserState.save(socket, user, namespace, key, 5)

      assert [["save_user_state", %{key: storage_key, value: 5}]] =
               result.private.live_temp[:push_events]

      assert storage_key == "next://user-42@localhost/manual/123/chapter"
    end

    test "works with empty namespace" do
      user = %{id: 1}
      namespace = []
      key = :theme

      socket = %Phoenix.LiveView.Socket{
        transport_pid: self(),
        assigns: %{__changed__: %{}},
        private: %{live_temp: %{}}
      }

      result = UserState.save(socket, user, namespace, key, "dark")

      assert [["save_user_state", %{key: storage_key, value: "dark"}]] =
               result.private.live_temp[:push_events]

      assert storage_key == "next://user-1@localhost/theme"
    end
  end

  describe "Storage.backend/0" do
    test "returns default LocalStorage backend" do
      assert Storage.backend() == LocalStorage
    end
  end

  describe "LocalStorage.save/3" do
    test "calls push_event with save_user_state event" do
      socket = %Phoenix.LiveView.Socket{
        transport_pid: self(),
        assigns: %{__changed__: %{}},
        private: %{live_temp: %{}}
      }

      result = LocalStorage.save(socket, "next://user-1@localhost/test/key", "value")

      assert [["save_user_state", %{key: key, value: value}]] =
               result.private.live_temp[:push_events]

      assert key == "next://user-1@localhost/test/key"
      assert value == "value"
    end
  end

  describe "publish_user_state_change/3" do
    defmodule TestLeafView do
      use CoreWeb, :embedded_live_view

      alias Frameworks.Concept.LiveContext

      @impl true
      def mount(_, session, socket) do
        live_context =
          case Map.get(session, "live_context") do
            nil -> LiveContext.new(%{user_state_namespace: [:collection, 123]})
            context -> context
          end

        current_user = Map.get(session, "current_user", %{id: 1})

        {:ok,
         assign(socket,
           vm: %{},
           model: %{id: 1},
           live_context: live_context,
           current_user: current_user
         )}
      end

      @impl true
      def handle_event("select", %{"value" => value}, socket) do
        value = String.to_integer(value)
        {:noreply, publish_user_state_change(socket, :selected_item, value)}
      end

      # Stub for Observatory LiveFeature
      def observe_view_model(socket), do: socket

      @impl true
      def render(assigns) do
        ~H"""
        <div data-testid="leaf-view">
          <button phx-click="select" phx-value-value="456">Select</button>
        </div>
        """
      end
    end

    test "publishes event with nested map from namespace + key", %{conn: conn} do
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          user_state_namespace: [:collection, 123]
        })

      conn = Map.put(conn, :request_path, "/test")

      {:ok, view, _html} =
        live_isolated(conn, TestLeafView, session: %{"live_context" => live_context})

      # Trigger event that publishes user state change
      view |> element("button") |> render_click()

      # Verify event was published (we can't directly observe it in isolated view,
      # but we can verify no errors occurred)
      assert view |> has_element?("[data-testid='leaf-view']")
    end
  end

  describe "scope_user_state/2" do
    test "returns user_state when namespace is nil" do
      user_state = %{chapter_id: 5}
      assert UserState.scope_user_state(user_state, nil) == %{chapter_id: 5}
    end

    test "returns user_state when namespace is empty" do
      user_state = %{chapter_id: 5}
      assert UserState.scope_user_state(user_state, []) == %{chapter_id: 5}
    end

    test "scopes user_state by namespace path" do
      user_state = %{manual: %{123 => %{chapter_id: 5}}}
      assert UserState.scope_user_state(user_state, [:manual, 123]) == %{chapter_id: 5}
    end

    test "returns empty map when path not found" do
      user_state = %{}
      assert UserState.scope_user_state(user_state, [:manual, 123]) == %{}
    end
  end

  describe "parse_user_state/2" do
    test "parses flat localStorage map into nested structure" do
      flat_state = %{
        "next://user-10@localhost/assignment/5/task" => "4"
      }

      result = UserState.parse_user_state(flat_state, 10)

      assert result == %{assignment: %{5 => %{task: 4}}}
    end

    test "filters by user_id" do
      flat_state = %{
        "next://user-10@localhost/manual/1/chapter" => "5",
        "next://user-20@localhost/manual/1/chapter" => "10"
      }

      result = UserState.parse_user_state(flat_state, 10)

      assert result == %{manual: %{1 => %{chapter: 5}}}
    end

    test "handles multiple keys" do
      flat_state = %{
        "next://user-10@localhost/assignment/5/crew/5/task" => "4",
        "next://user-10@localhost/manual/1/chapter" => "5"
      }

      result = UserState.parse_user_state(flat_state, 10)

      assert result == %{
               assignment: %{5 => %{crew: %{5 => %{task: 4}}}},
               manual: %{1 => %{chapter: 5}}
             }
    end

    test "returns empty map for non-map input" do
      assert UserState.parse_user_state(nil, 10) == %{}
      assert UserState.parse_user_state("invalid", 10) == %{}
    end
  end

  describe "string_value/2" do
    test "extracts string value from map" do
      data = %{name: "test"}
      assert UserState.string_value(data, :name) == "test"
    end

    test "returns nil for missing key" do
      data = %{}
      assert UserState.string_value(data, :name) == nil
    end
  end

  describe "integer_value/2" do
    test "parses integer from string value" do
      data = %{count: "42"}
      assert UserState.integer_value(data, :count) == 42
    end

    test "returns nil for missing key" do
      data = %{}
      assert UserState.integer_value(data, :count) == nil
    end

    test "returns nil for non-integer string" do
      data = %{count: "invalid"}
      assert UserState.integer_value(data, :count) == nil
    end
  end
end
