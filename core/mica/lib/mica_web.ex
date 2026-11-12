defmodule MicaWeb do
  @moduledoc """
  Mica's web module: the entrypoint for defining Mica's web interface, such as
  controllers, views, channels and so on.

      use MicaWeb, {:controller, [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}
      use MicaWeb, :html

  The blocks are defined in `MicaWeb.Web`. Code of a SaaS uses its own web module
  (`NextWeb`, `MicaSaasWeb`), so its `~p` is verified against that SaaS's router.
  """

  use MicaWeb.Web, router: MicaWeb.Router, endpoint: MicaWeb.Endpoint

  def static_paths, do: MicaWeb.Path.statics()
end
