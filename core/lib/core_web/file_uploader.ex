defmodule CoreWeb.FileUploader do
  @moduledoc """
  """

  @callback save_file(socket :: Socket.t(), uploaded_file :: any()) :: Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour CoreWeb.FileUploader

      def init_file_uploader(socket, key) do
        "init_file_uploader" |> IO.inspect(label: "1")
        socket
        |> allow_upload(key,
          accept: ~w(.png .jpg .jpeg),
          progress: &handle_progress/3,
          auto_upload: true
        )
      end

      def handle_progress(_key, entry, socket) do
        "handle_progress" |> IO.inspect(label: "1")
        if entry.done? do
          "handle_progress" |> IO.inspect(label: "2")
          uploaded_file =
            socket
            |> consume_file(entry)
          "handle_progress" |> IO.inspect(label: "3")

          {:noreply, socket |> save_file(uploaded_file)}
        else
          "handle_progress" |> IO.inspect(label: "4")
          {:noreply, socket}
        end
      end

      def consume_file(socket, entry) do
        "consume_file" |> IO.inspect(label: "1")
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          "consume_file" |> IO.inspect(label: "2")
          file = "#{entry.uuid}.#{ext(entry)}"
          dest = Path.join("priv/static/uploads", file)
          File.cp!(path, dest)
          "consume_file" |> IO.inspect(label: "3")
          CoreWeb.Router.Helpers.static_path(socket, "/uploads/#{file}")
        end)
      end

      def ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end
    end
  end
end
