defmodule Systems.Feldspar.ControllerTest do
  use CoreWeb.ConnCase, async: false

  alias Systems.Assignment
  alias Systems.Storage

  # ============================================================================
  # Donate endpoint tests
  # ============================================================================

  describe "donate/2 - missing required fields" do
    setup :login_as_member

    test "returns 400 when key is missing", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      context = Jason.encode!(%{assignment_id: 1, task: "1", participant: "p1", group: "test"})

      conn =
        conn
        |> post("/api/feldspar/donate", %{"data" => upload, "context" => context})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: key"}
    end

    test "returns 400 when data is missing", %{conn: conn} do
      context = Jason.encode!(%{assignment_id: 1, task: "1", participant: "p1", group: "test"})

      conn =
        conn
        |> post("/api/feldspar/donate", %{"key" => "test-key", "context" => context})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: data"}
    end

    test "returns 400 when both key and data are missing", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/donate", %{})

      assert json_response(conn, 400) == %{
               "error" => "Missing required fields: key, data, context"
             }
    end
  end

  describe "donate/2 - invalid context" do
    setup :login_as_member

    test "returns 400 when context is nil", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      conn =
        conn
        |> post("/api/feldspar/donate", %{"key" => "test-key", "data" => upload})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: context"}
    end

    test "returns 400 when context is empty string", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => ""
        })

      assert json_response(conn, 400) == %{"error" => "Missing or invalid context"}
    end

    test "returns 400 when context is empty JSON object", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => "{}"
        })

      assert json_response(conn, 400) == %{"error" => "Missing or invalid context"}
    end

    test "returns 400 when context is invalid JSON", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => "not valid json"
        })

      assert json_response(conn, 400) == %{"error" => "Missing or invalid context"}
    end
  end

  describe "donate/2 - authentication" do
    test "returns 401 when user is not authenticated", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      context = Jason.encode!(%{assignment_id: 1, task: "1", participant: "p1", group: "test"})

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      assert json_response(conn, 401) == %{"error" => "Not authenticated"}
    end
  end

  describe "donate/2 - no storage endpoint" do
    setup :login_as_member

    test "returns 422 when assignment has no storage endpoint", %{conn: conn} do
      assignment = Assignment.Factories.create_assignment(31, 0, :online)

      upload = %Plug.Upload{
        path: create_temp_file("test data"),
        filename: "data.json",
        content_type: "application/json"
      }

      context =
        Jason.encode!(%{
          assignment_id: assignment.id,
          task: "1",
          participant: "p1",
          group: "test"
        })

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      assert json_response(conn, 422) == %{"error" => "No storage endpoint configured"}
    end
  end

  describe "donate/2 - success" do
    setup :login_as_member

    test "returns 200 when all inputs are valid", %{conn: conn, user: _user} do
      assignment = create_assignment_with_storage()

      upload = %Plug.Upload{
        path: create_temp_file("{\"test\": \"data\"}"),
        filename: "data.json",
        content_type: "application/json"
      }

      context =
        Jason.encode!(%{
          assignment_id: assignment.id,
          task: "9",
          participant: "test_participant",
          group: "tiktok"
        })

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      response = json_response(conn, 200)
      assert response["status"] == "ok"
    end

    test "returns 422 without assignment_id in context", %{conn: conn} do
      upload = %Plug.Upload{
        path: create_temp_file("{\"test\": \"data\"}"),
        filename: "data.json",
        content_type: "application/json"
      }

      context =
        Jason.encode!(%{
          task: "9",
          participant: "test_participant",
          group: "tiktok"
        })

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      response = json_response(conn, 422)
      assert response["error"] == "No storage endpoint configured"
    end
  end

  describe "donate/2 - file read error" do
    setup :login_as_member

    test "returns 422 when file cannot be read", %{conn: conn} do
      upload = %Plug.Upload{
        path: "/nonexistent/path/to/file.json",
        filename: "data.json",
        content_type: "application/json"
      }

      context =
        Jason.encode!(%{
          assignment_id: 1,
          task: "1",
          participant: "p1",
          group: "test"
        })

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      assert json_response(conn, 422) == %{"error" => "Failed to read upload"}
    end
  end

  describe "donate/2 - scheduling failure" do
    setup :login_as_member

    setup do
      # Save original config
      original_storage_config = Application.get_env(:core, :storage)

      on_exit(fn ->
        Application.put_env(:core, :storage, original_storage_config)
      end)

      :ok
    end

    test "returns 422 when job scheduling fails", %{conn: conn} do
      import Mox

      assignment = create_assignment_with_storage()

      upload = %Plug.Upload{
        path: create_temp_file("{\"test\": \"data\"}"),
        filename: "data.json",
        content_type: "application/json"
      }

      context =
        Jason.encode!(%{
          assignment_id: assignment.id,
          task: "1",
          participant: "test_participant",
          group: "test"
        })

      # Configure mock job scheduler
      storage_config = Application.get_env(:core, :storage)

      Application.put_env(
        :core,
        :storage,
        Keyword.put(storage_config, :job_scheduler, Systems.Storage.MockJobScheduler)
      )

      # Mock insert to return an error - this causes the Multi to fail with 4-tuple
      expect(Systems.Storage.MockJobScheduler, :insert, fn _changeset ->
        {:error, %Ecto.Changeset{valid?: false, errors: [queue: {"invalid", []}]}}
      end)

      conn =
        conn
        |> post("/api/feldspar/donate", %{
          "key" => "test-key",
          "data" => upload,
          "context" => context
        })

      # Should return 422 with "Scheduling failed", not crash with 500
      response = json_response(conn, 422)
      assert response["error"] == "Scheduling failed"
    end
  end

  describe "donate/2 - concurrent uploads" do
    setup :login_as_member

    @tag timeout: 120_000
    @tag :slow
    test "concurrent large file uploads all succeed", %{conn: conn} do
      assignment = create_assignment_with_storage()
      num_requests = 20
      line_count = 50_000

      content = create_large_json_content(line_count)
      IO.puts("\nContent size: #{Float.round(byte_size(content) / 1024 / 1024, 2)} MB")

      temp_files =
        for i <- 1..num_requests do
          path =
            Path.join(System.tmp_dir!(), "concurrent_test_#{i}_#{:erlang.unique_integer()}.json")

          File.write!(path, content)
          path
        end

      on_exit(fn -> Enum.each(temp_files, &File.rm/1) end)

      IO.puts("Sending #{num_requests} concurrent requests...")
      start_time = System.monotonic_time(:millisecond)

      tasks =
        temp_files
        |> Enum.with_index(1)
        |> Enum.map(fn {path, i} ->
          Task.async(fn ->
            upload = %Plug.Upload{
              path: path,
              filename: "data_#{i}.json",
              content_type: "application/json"
            }

            context =
              Jason.encode!(%{
                assignment_id: assignment.id,
                task: "#{i}",
                participant: "participant_#{i}",
                group: "concurrent_test"
              })

            result =
              conn
              |> post("/api/feldspar/donate", %{
                "key" => "test-key-#{i}",
                "data" => upload,
                "context" => context
              })

            status = result.status
            IO.puts("  Request #{i}: HTTP #{status}")
            {i, status, result.resp_body}
          end)
        end)

      results = Task.await_many(tasks, 120_000)

      end_time = System.monotonic_time(:millisecond)
      IO.puts("\nDuration: #{end_time - start_time}ms")

      successes = Enum.filter(results, fn {_, status, _} -> status == 200 end)
      failures = Enum.reject(results, fn {_, status, _} -> status == 200 end)

      IO.puts("Successes: #{length(successes)}/#{num_requests}")

      if length(failures) > 0 do
        IO.puts("\nFailures:")

        Enum.each(failures, fn {i, status, body} ->
          IO.puts("  Request #{i}: HTTP #{status} - #{body}")
        end)
      end

      assert length(successes) == num_requests,
             "Expected #{num_requests} successes, got #{length(successes)}. Failures: #{inspect(failures)}"
    end
  end

  # ============================================================================
  # Log endpoint tests
  # ============================================================================

  describe "log/2 - missing required fields" do
    setup :login_as_member

    test "returns 400 when level is missing", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"message" => "test message"})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: level"}
    end

    test "returns 400 when message is missing", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "info"})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: message"}
    end

    test "returns 400 when both level and message are missing", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{})

      assert json_response(conn, 400) == %{"error" => "Missing required fields: level, message"}
    end
  end

  describe "log/2 - invalid level" do
    setup :login_as_member

    test "returns 400 for invalid level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "invalid", "message" => "test"})

      assert json_response(conn, 400) == %{
               "error" => "Invalid level. Must be one of: debug, info, warn, error"
             }
    end

    test "returns 400 for empty level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "", "message" => "test"})

      assert json_response(conn, 400) == %{
               "error" => "Invalid level. Must be one of: debug, info, warn, error"
             }
    end
  end

  describe "log/2 - authentication" do
    test "returns 401 when user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "info", "message" => "test"})

      assert json_response(conn, 401) == %{"error" => "Not authenticated"}
    end
  end

  describe "log/2 - success cases" do
    setup :login_as_member

    test "accepts debug level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "debug", "message" => "debug message"})

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "accepts info level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "info", "message" => "info message"})

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "accepts warn level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "warn", "message" => "warning message"})

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "accepts error level", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "error", "message" => "error message"})

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "accepts optional context", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{
          "level" => "info",
          "message" => "message with context",
          "context" => %{
            "assignment_id" => 123,
            "participant" => "p1",
            "key" => "test-key"
          }
        })

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "works without context", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{
          "level" => "info",
          "message" => "message without context"
        })

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "handles empty message", %{conn: conn} do
      conn =
        conn
        |> post("/api/feldspar/log", %{"level" => "info", "message" => ""})

      assert json_response(conn, 200) == %{"status" => "ok"}
    end
  end

  describe "log/2 - rate limiting" do
    @describetag :rate_limit_test

    setup :login_as_member

    setup do
      # Set very low limit and restart Rate.Server with new config
      low_limit_config = [
        prune_interval: 60 * 60 * 1000,
        quotas: [
          [service: :feldspar_log, limit: 1, unit: :call, window: :minute, scope: :local]
        ]
      ]

      # Stop, delete, and re-add with new config
      Supervisor.terminate_child(Core.Supervisor, Systems.Rate.Server)
      Supervisor.delete_child(Core.Supervisor, Systems.Rate.Server)
      Supervisor.start_child(Core.Supervisor, {Systems.Rate.Server, low_limit_config})

      on_exit(fn ->
        # Restore original config
        original_config = Application.get_env(:core, :rate)
        Supervisor.terminate_child(Core.Supervisor, Systems.Rate.Server)
        Supervisor.delete_child(Core.Supervisor, Systems.Rate.Server)
        Supervisor.start_child(Core.Supervisor, {Systems.Rate.Server, original_config})
      end)

      :ok
    end

    test "returns 429 when rate limit exceeded", %{conn: conn} do
      # Use unique IP to avoid interference from other tests
      unique_ip = {10, 0, 0, :erlang.unique_integer([:positive]) |> rem(255)}

      # First request should succeed
      assert conn
             |> Map.put(:remote_ip, unique_ip)
             |> post("/api/feldspar/log", %{"level" => "info", "message" => "first"})
             |> json_response(200) == %{"status" => "ok"}

      # Second request should be rate limited
      response =
        conn
        |> Map.put(:remote_ip, unique_ip)
        |> post("/api/feldspar/log", %{"level" => "info", "message" => "second"})
        |> json_response(429)

      assert response["error"] =~ "Rate limited"
    end
  end

  # ============================================================================
  # Helper functions
  # ============================================================================

  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "test_upload_#{:erlang.unique_integer()}.json")
    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp create_large_json_content(line_count) do
    entries =
      Enum.map_join(1..line_count, ",\n", fn i ->
        ~s({"id":#{i},"data":"entry_#{i}_with_some_padding_to_increase_size"})
      end)

    "[#{entries}]"
  end

  defp create_assignment_with_storage do
    # Create assignment first
    assignment = Assignment.Factories.create_assignment(31, 0, :online)

    # Create project node with required name field
    project_node =
      Factories.insert!(:project_node, %{
        name: "test_node",
        project_path: []
      })

    # Create storage endpoint using Storage.Public.prepare_endpoint
    storage_endpoint =
      Storage.Public.prepare_endpoint(:builtin, %{key: "test_key_#{:erlang.unique_integer()}"})
      |> Core.Repo.insert!()

    # Create project_item linking assignment to the node
    Factories.insert!(:project_item, %{
      name: "assignment_item",
      project_path: [],
      node_id: project_node.id,
      assignment_id: assignment.id
    })

    # Create project_item linking storage endpoint to the same node
    Factories.insert!(:project_item, %{
      name: "storage_item",
      project_path: [],
      node_id: project_node.id,
      storage_endpoint_id: storage_endpoint.id
    })

    assignment
  end
end
