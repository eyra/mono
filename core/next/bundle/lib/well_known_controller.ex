defmodule Next.WellKnownController do
  @moduledoc """
  Serves the apple-app-site-association file, so iOS opens invitation links
  (`/assignment/*`) in the Next app (UC-SENSE-03).

  Both app IDs are listed on every environment: iOS only links a domain to an
  app whose Associated Domains entitlement names that domain, so the Dev app
  (`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
  and Prod builds share `co.eyra.next`.
  """
  use CoreWeb, {:controller, [formats: [:json]]}

  @app_ids ["XNWQJGGM96.co.eyra.next", "XNWQJGGM96.co.eyra.next.dev"]

  def apple_app_site_association(conn, _params) do
    json(conn, %{
      applinks: %{details: [%{appIDs: @app_ids, components: [%{"/" => "/assignment/*"}]}]}
    })
  end
end
