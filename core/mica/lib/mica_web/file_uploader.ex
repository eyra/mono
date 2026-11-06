defmodule MicaWeb.FileUploader do
  @moduledoc """
  """

  alias Phoenix.LiveView.Socket

  @allowed_filename_pattern ~r"^[a-z0-9][a-z0-9\-]+[a-z0-9](\.[a-z]{3,4})?$"

  @callback process_file(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback file_upload_start(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback file_upload_progress(socket :: Socket.t(), info :: any()) :: Socket.t()
  @callback pre_process_file(info :: any()) :: map()
  @callback file_upload_error(socket :: Socket.t(), reason :: any()) :: Socket.t()

  @optional_callbacks file_upload_start: 2,
                      file_upload_progress: 2,
                      pre_process_file: 1,
                      file_upload_error: 2

  def get_upload_path(filename) do
    unless Regex.match?(@allowed_filename_pattern, filename) do
      throw(:invalid_filename)
    end

    root = Mica.Env.get(:upload_path, "priv/static/uploads")
    Path.join(root, filename)
  end

  defmacro __using__(opts) do
    store = Keyword.get(opts, :store, Systems.Content.Public)
    accept = Keyword.get(opts, :accept, ~w"*.*")

    quote do
      @behaviour MicaWeb.FileUploader

      # Skip init if this key is already registered
      def init_file_uploader(%{assigns: %{uploads: uploads}} = socket, key)
          when is_map_key(uploads, key),
          do: socket

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
        config = Mica.Env.fetch!(MicaWeb.FileUploader)
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
            case consume_file(socket, entry) do
              {:error, reason} -> handle_upload_failure(socket, reason)
              upload_result -> process_file(socket, upload_result)
            end
          else
            socket
          end

        {:noreply, socket}
      end

      defp handle_upload_failure(socket, reason) do
        if function_exported?(__MODULE__, :file_upload_error, 2) do
          apply(__MODULE__, :file_upload_error, [socket, reason])
        else
          Frameworks.Pixel.Flash.push_error(socket)
        end
      end

      def consume_file(socket, entry) do
        consume_uploaded_entry(socket, entry, fn %{path: tmp_path} ->
          case unquote(store).store(tmp_path, entry.client_name) do
            {:error, reason} -> {:ok, {:error, reason}}
            path -> {:ok, stored_file(entry, tmp_path, path)}
          end
        end)
      end

      defp stored_file(entry, tmp_path, path) do
        public_url = unquote(store).get_public_url(path)

        info =
          if function_exported?(__MODULE__, :pre_process_file, 1) do
            apply(__MODULE__, :pre_process_file, [
              %{entry: entry, tmp_path: tmp_path, public_url: public_url}
            ])
          else
            %{}
          end

        Map.merge(
          %{path: path, public_url: public_url, original_filename: entry.client_name},
          info
        )
      end

      def ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end
    end
  end
end
