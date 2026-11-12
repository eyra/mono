defmodule MicaWeb do
  @moduledoc """
  Mica's web module: the entrypoint for defining Mica's web interface, such as
  controllers, views, channels and so on.

      use MicaWeb, {:controller, [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}
      use MicaWeb, :html

  The blocks are defined in `MicaWeb.Web`. Mica has no router of its own, so its
  code builds paths with `~m` (`MicaWeb.Path`), which every SaaS checks against
  its router. Code of a SaaS uses its own web module (`NextWeb`, `MicaSaasWeb`),
  so its `~p` is verified against that SaaS's router.
  """

  use MicaWeb.Web

  def static_paths, do: MicaWeb.Path.statics()
end
