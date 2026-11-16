defmodule NextWeb do
  @moduledoc """
  Next's web module. Next's code uses it instead of `MicaWeb`:

      use NextWeb, :routed_live_view
      use NextWeb, {:controller, [formats: [:json]]}

  The blocks are `MicaWeb.Web`'s; `~p` is verified against the router given here.
  """

  use MicaWeb.Web, router: MicaWeb.Router, endpoint: NextWeb.Endpoint
end
