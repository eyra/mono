defmodule Systems.Content.LocalFSStreamTest do
  use Core.DataCase
  alias Systems.Content.LocalFS

  describe "stream/1" do
    setup do
      # Create a temporary test file
      upload_path = Application.get_env(:core, :upload_path)
      File.mkdir_p!(upload_path)

      test_content = """
      TY  - JOUR
      TI  - Test Article
      AU  - Smith, John
      PY  - 2023
      AB  - This is a test abstract
      ER  -

      TY  - BOOK
      TI  - Another Test
      AU  - Doe, Jane
      PY  - 2024
      ER  -
      """

      filename = "test_#{Ecto.UUID.generate()}.ris"
      file_path = Path.join(upload_path, filename)
      File.write!(file_path, test_content)

      on_exit(fn ->
        File.rm_rf(file_path)
      end)

      {:ok, file_path: file_path, filename: filename, content: test_content}
    end

    test "streams file content from direct path", %{
      file_path: file_path,
      content: expected_content
    } do
      assert {:ok, stream} = LocalFS.stream(file_path)

      # Collect the stream
      result = stream |> Enum.join("")

      assert result == expected_content
    end

    test "streams file content from URL format", %{filename: filename, content: expected_content} do
      # Simulate URL format
      base_url = Application.get_env(:core, :base_url)
      url = "#{base_url}/uploads/#{filename}"

      assert {:ok, stream} = LocalFS.stream(url)

      result = stream |> Enum.join("")

      assert result == expected_content
    end

    test "returns error for non-existent file" do
      assert {:error, %Systems.Content.LocalFS.Error{message: message}} =
               LocalFS.stream("/non/existent/file.ris")

      assert message =~ "not found"
    end

    test "streams large file in chunks", %{file_path: _} do
      # Create a large test file (1MB)
      upload_path = Application.get_env(:core, :upload_path)
      large_filename = "large_test_#{Ecto.UUID.generate()}.ris"
      large_file_path = Path.join(upload_path, large_filename)

      # Generate 1MB of RIS-like content
      large_content = String.duplicate("TY  - JOUR\nTI  - Test\nER  -\n", 35_000)
      File.write!(large_file_path, large_content)

      on_exit(fn -> File.rm_rf(large_file_path) end)

      assert {:ok, stream} = LocalFS.stream(large_file_path)

      # Get the configured chunk size
      expected_chunk_size =
        Application.fetch_env!(:core, :paper)
        |> Keyword.fetch!(:ris_stream_chunk_size)

      # Verify it's actually streaming
      chunks = stream |> Enum.to_list()

      # Should have multiple chunks for a 1MB file
      assert length(chunks) > 10

      # Each chunk should be the configured size (except possibly the last)
      chunk_sizes = Enum.map(chunks, &byte_size/1)
      assert Enum.all?(Enum.drop(chunk_sizes, -1), &(&1 == expected_chunk_size))

      # Verify content is complete
      result = Enum.join(chunks, "")
      assert byte_size(result) == byte_size(large_content)
    end
  end
end
