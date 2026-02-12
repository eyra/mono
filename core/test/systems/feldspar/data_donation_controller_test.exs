defmodule Systems.Feldspar.DataDonationControllerTest do
  use CoreWeb.ConnCase, async: false

  alias Systems.Assignment
  alias Systems.Storage

  describe "create/2 - missing required fields" do
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

  describe "create/2 - invalid context" do
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

  describe "create/2 - authentication" do
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

  describe "create/2 - no storage endpoint" do
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

  describe "create/2 - success" do
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

  describe "create/2 - file read error" do
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

  describe "create/2 - scheduling failure" do
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

  describe "create/2 - concurrent uploads" do
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
