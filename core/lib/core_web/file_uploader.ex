defmodule CoreWeb.FileUploader do
  @moduledoc """
  """

  alias Phoenix.LiveView.Socket

  @allowed_filename_pattern ~r"^[a-z0-9][a-z0-9\-]+[a-z0-9](\.[a-z]{3,4})?$"

  @callback process_file(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback file_upload_start(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback file_upload_progress(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback pre_process_file(info :: any()) :: map()

  @optional_callbacks file_upload_start: 2, file_upload_progress: 2, pre_process_file: 1

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

      def handle_progress(
            _key,
            %{uuid: upload_entry_id, progress: progress, client_name: client_name} = entry,
            socket
          ) do
        socket =
          if upload_entry_id != Map.get(socket.assigns, :upload_entry_id) do
            if function_exported?(__MODULE__, :file_upload_start, 2) do
              apply(__MODULE__, :file_upload_start, [socket, {client_name, progress}])
            else
              socket
            end
            |> assign(upload_entry_id: upload_entry_id)
          else
            socket
          end

        socket =
          if function_exported?(__MODULE__, :file_upload_progress, 2) do
            apply(__MODULE__, :file_upload_progress, [socket, {client_name, progress}])
          else
            socket
          end

        socket =
          if entry.done? do
            upload_result = consume_file(socket, entry)
            socket |> process_file(upload_result)
          else
            socket
          end

        {:noreply, socket}
      end

      def consume_file(socket, entry) do
        consume_uploaded_entry(socket, entry, fn %{path: tmp_path} ->
          path = unquote(store).store(tmp_path, entry.client_name)
          public_url = unquote(store).get_public_url(path)

          info =
            if function_exported?(__MODULE__, :pre_process_file, 1) do
              apply(__MODULE__, :pre_process_file, [
                %{entry: entry, tmp_path: tmp_path, public_url: public_url}
              ])
            else
              %{}
            end

          result =
            Map.merge(
              %{path: path, public_url: public_url, original_filename: entry.client_name},
              info
            )

          {:ok, result}
        end)
      end

      def ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end
    end
  end
end
