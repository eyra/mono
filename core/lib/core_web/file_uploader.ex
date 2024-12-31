defmodule CoreWeb.FileUploader do
  @moduledoc """
  """

  @allowed_filename_pattern ~r"^[a-z0-9][a-z0-9\-]+[a-z0-9](\.[a-z]{3,4})?$"

  @callback process_file(socket :: Phoenix.LiveView.Socket.t(), uploaded_file :: any()) ::
              Phoenix.LiveView.Socket.t()

  def get_upload_path(filename) do
    unless Regex.match?(@allowed_filename_pattern, filename) do
      throw(:invalid_filename)
    end

    root = Application.get_env(:core, :upload_path, "priv/static/uploads")
    Path.join(root, filename)
  end

  defmacro __using__(opts) do
    store = Keyword.get(opts, :store, Systems.Content.Public)
    accept = Keyword.get(opts, :accept, ~w"*.*")

    quote do
      @behaviour CoreWeb.FileUploader

      # Skip init if it already has been called
      def init_file_uploader(%{assigns: %{uploads: _uploads}} = socket, _key), do: socket

      def init_file_uploader(socket, key) do
        socket
        |> allow_upload(key,
          accept: unquote(accept),
          progress: &handle_progress/3,
          max_file_size: get_max_file_size(),
          auto_upload: true
        )
      end

      def get_max_file_size() do
        config = Application.fetch_env!(:core, CoreWeb.FileUploader)
        Keyword.fetch!(config, :max_file_size)
      end

      def handle_progress(_key, entry, socket) do
        if entry.done? do
          upload_result = consume_file(socket, entry)
          {:noreply, socket |> process_file(upload_result)}
        else
          {:noreply, socket}
        end
      end

      def consume_file(socket, entry) do
        consume_uploaded_entry(socket, entry, fn %{path: tmp_path} ->
          path = apply(unquote(store), :store, [tmp_path, entry.client_name])
          public_url = apply(unquote(store), :get_public_url, [path])
          {:ok, {path, public_url, entry.client_name}}
        end)
      end

      def ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end
    end
  end
end
