defmodule CoreWeb.Live.DataUploader.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser])

        live("/data-uploader/:id", DataUploader.Uploader)
      end
    end
  end
end
