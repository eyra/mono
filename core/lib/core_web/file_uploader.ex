defmodule CoreWeb.FileUploader do
  @moduledoc """
  """

  @allowed_filename_pattern ~r"^[a-z0-9][a-z0-9\-]+[a-z0-9]\.[a-z]{3,4}$"

  @callback process_file(socket :: Socket.t(), uploaded_file :: any()) :: Socket.t()

  def get_static_path(filename) do
    unless Regex.match?(@allowed_filename_pattern, filename) do
      throw(:invalid_filename)
    end

    root = Application.get_env(:core, :static_path, "priv/static/uploads")
    Path.join(root, filename)
  end

  defmacro __using__(accept) do
    quote do
      @behaviour CoreWeb.FileUploader

      # Skip init if it already has been called
      def init_file_uploader(%{assigns: %{uploads: _uploads}} = socket, _key), do: socket

      def init_file_uploader(socket, key) do
        socket
        |> allow_upload(key,
          accept: unquote(accept),
          progress: &handle_progress/3,
          auto_upload: true
        )
      end

      def handle_progress(_key, entry, socket) do
        IO.puts("handle_progress")

        if entry.done? do
          upload_result = consume_file(socket, entry)
          {:noreply, socket |> process_file(upload_result)}
        else
          {:noreply, socket}
        end
      end

      def consume_file(socket, entry) do
        IO.puts("consume_file")

        consume_uploaded_entry(socket, entry, fn %{path: tmp_path} ->
          file = "#{entry.uuid}.#{ext(entry)}"
          local_full_path = CoreWeb.FileUploader.get_static_path(file)
          File.cp!(tmp_path, local_full_path)
          local_relative_path = CoreWeb.Endpoint.static_path("/uploads/#{file}")
          {:ok, {local_relative_path, local_full_path, entry.client_name}}
        end)
      end

      def ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end
    end
  end
end
