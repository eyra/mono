# Run with: mix run test_concurrent_donate.exs
#
# Before running:
# 1. Login to http://localhost:4000 in your browser
# 2. Copy the _core_key cookie value from browser dev tools
# 3. Set it below in @session_cookie

defmodule ConcurrentDonateTest do
  @base_url "http://localhost:4000"
  @assignment_id 4
  @num_requests 20
  # 50K lines per file
  @line_count 50_000

  # PASTE YOUR SESSION COOKIE HERE:
  @session_cookie "_core_key=PASTE_COOKIE_HERE"

  def run do
    IO.puts("=== Concurrent Data Donation Test ===")
    IO.puts("Requests: #{@num_requests}")
    IO.puts("Lines per file: #{@line_count}")
    IO.puts("")

    # Generate large content
    IO.puts("Generating test content...")
    content = generate_large_content(@line_count)
    content_size = byte_size(content)
    IO.puts("Content size: #{Float.round(content_size / 1024 / 1024, 2)} MB")
    IO.puts("")

    # Create temp files
    IO.puts("Creating #{@num_requests} temp files...")

    temp_files =
      for i <- 1..@num_requests do
        path = Path.join(System.tmp_dir!(), "donate_test_#{i}_#{:rand.uniform(100_000)}.json")
        File.write!(path, content)
        path
      end

    IO.puts("Sending #{@num_requests} concurrent requests...")
    IO.puts("")
    start_time = System.monotonic_time(:millisecond)

    # Send concurrent requests using Tasks
    tasks =
      temp_files
      |> Enum.with_index(1)
      |> Enum.map(fn {path, i} ->
        Task.async(fn ->
          send_donation(path, i)
        end)
      end)

    results = Task.await_many(tasks, 180_000)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    # Cleanup
    Enum.each(temp_files, &File.rm/1)

    # Results
    IO.puts("")
    IO.puts("=== Results ===")
    IO.puts("Duration: #{duration}ms (#{Float.round(duration / 1000, 1)}s)")

    successes = Enum.filter(results, &match?({:ok, 200, _}, &1))
    failures = Enum.reject(results, &match?({:ok, 200, _}, &1))

    IO.puts("Successes: #{length(successes)}/#{@num_requests}")
    IO.puts("Failures: #{length(failures)}")

    if length(failures) > 0 do
      IO.puts("")
      IO.puts("Failed requests:")

      Enum.each(failures, fn
        {:ok, status, body} -> IO.puts("  HTTP #{status}: #{String.slice(body, 0, 100)}")
        {:error, reason} -> IO.puts("  Error: #{inspect(reason)}")
      end)
    end

    IO.puts("")

    if length(successes) == @num_requests do
      IO.puts("✅ All requests succeeded!")
    else
      IO.puts("❌ Some requests failed - issue reproduced!")
    end
  end

  defp generate_large_content(line_count) do
    entries =
      1..line_count
      |> Enum.map(fn i ->
        ~s({"id":#{i},"data":"entry_#{i}_padding_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"})
      end)
      |> Enum.join(",\n")

    "[#{entries}]"
  end

  defp send_donation(file_path, request_num) do
    context =
      Jason.encode!(%{
        assignment_id: @assignment_id,
        task: "1",
        participant: "test_participant_#{request_num}_#{:rand.uniform(100_000)}",
        group: "concurrent_test"
      })

    boundary = "----WebKitFormBoundary#{:rand.uniform(1_000_000_000)}"
    file_content = File.read!(file_path)

    body = """
    --#{boundary}\r
    Content-Disposition: form-data; name="key"\r
    \r
    test-key-#{request_num}\r
    --#{boundary}\r
    Content-Disposition: form-data; name="context"\r
    \r
    #{context}\r
    --#{boundary}\r
    Content-Disposition: form-data; name="data"; filename="data.json"\r
    Content-Type: application/json\r
    \r
    #{file_content}\r
    --#{boundary}--\r
    """

    headers = [
      {"Content-Type", "multipart/form-data; boundary=#{boundary}"},
      {"Cookie", @session_cookie}
    ]

    url = "#{@base_url}/api/feldspar/donate"

    case :httpc.request(
           :post,
           {String.to_charlist(url),
            Enum.map(headers, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end),
            String.to_charlist("multipart/form-data; boundary=#{boundary}"),
            String.to_charlist(body)},
           [timeout: 60_000, connect_timeout: 10_000],
           []
         ) do
      {:ok, {{_, status, _}, _headers, resp_body}} ->
        IO.puts("  Request #{request_num}: HTTP #{status}")
        {:ok, status, to_string(resp_body)}

      {:error, reason} ->
        IO.puts("  Request #{request_num}: ERROR #{inspect(reason)}")
        {:error, reason}
    end
  end
end

# Start inets for :httpc
:inets.start()
:ssl.start()

ConcurrentDonateTest.run()
