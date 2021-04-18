defmodule CoreWeb.Live.DataUploader.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser])

        get("/data-uploader/:id", DataLoaderController, :index)
      end
    end
  end
end
