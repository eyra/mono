defmodule Next.Systems.WellKnown.Controller do
  @moduledoc """
  Serves the apple-app-site-association file, so iOS opens invitation links
  (`/assignment/*`) in the Next app (UC-SENSE-03), and so the sign-in sheet may
  hand an identity-provider sign-in back to the app on this host
  (`webcredentials`, see `Next.Systems.Account.NativeHandoff`).

  A panel link (`/a/:sqid?p=…`) is not one of them: its entry signs the panel
  participant in in the browser and sends them on to `/assignment/:id?via=affiliate`
  (`Systems.Affiliate.Controller`). That page stays in the browser, where the
  participant is signed in; the app would open it as its own user.

  Both app IDs are listed on every environment: iOS only links a domain to an
  app whose Associated Domains entitlement names that domain, so the Dev app
  (`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
  and Prod builds share `co.eyra.next`.
  """
  use NextWeb, {:controller, [formats: [:json]]}

  @app_ids ["XNWQJGGM96.co.eyra.next", "XNWQJGGM96.co.eyra.next.dev"]
  @components [
    %{"/" => "/assignment/*", "?" => %{"via" => "affiliate"}, "exclude" => true},
    %{"/" => "/assignment/*"}
  ]

  def apple_app_site_association(conn, _params) do
    json(conn, %{
      applinks: %{details: [%{appIDs: @app_ids, components: @components}]},
      webcredentials: %{apps: @app_ids}
    })
  end
end
