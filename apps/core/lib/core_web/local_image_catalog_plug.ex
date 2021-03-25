defmodule CoreWeb.LocalImageCatalogPlug do
  use Plug.Builder

  plug(Plug.Static,
    at: "/image-catalog",
    from: {:core, "priv/static/images"}
  )

  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end

  defmacro routes do
    quote do
      pipeline :local_image_catalog do
        plug(:accepts, ["html"])
      end

      scope "/", CoreWeb do
        pipe_through([:local_image_catalog])
        get("/image-catalog/*image", LocalImageCatalogPlug, nil)
      end
    end
  end
end
