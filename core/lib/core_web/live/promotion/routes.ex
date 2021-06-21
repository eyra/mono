defmodule CoreWeb.Live.Promotion.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser])

        live("/data-uploader/:id", DataUploader.Uploader)
        live("/promotion/:id", Promotion.Public)
      end
    end
  end
end
