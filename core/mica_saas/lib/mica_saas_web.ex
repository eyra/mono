defmodule MicaSaasWeb do
  @moduledoc """
  Self's web module. Self's code uses it instead of `MicaWeb`:

      use MicaSaasWeb, :routed_live_view
      use MicaSaasWeb, {:controller, [formats: [:html]]}

  The blocks are `MicaWeb.Web`'s; `~p` is verified against the router given here.
  """

  use MicaWeb.Web, router: MicaWeb.Router, endpoint: MicaSaasWeb.Endpoint
end
