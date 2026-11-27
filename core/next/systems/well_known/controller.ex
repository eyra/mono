defmodule Next.Systems.WellKnown.Controller do
  @moduledoc """
  Serves the apple-app-site-association file, so the sign-in sheet may hand an
  identity-provider sign-in back to the Next iOS app on this host
  (`webcredentials`, see `Next.Systems.Account.NativeHandoff`).

  It lists no app links. For now the native apps don't open pages from outside
  (sprint decision, 25 Nov): an invitation link (`/assignment/*`) opens in the
  browser, and the apps' home page lists the participant's assignments. Should
  app links come back, they must leave out a panel link's study
  (`/assignment/:id?via=affiliate`, where `Systems.Affiliate.Controller` sends a
  panel participant it signed in in the browser) and the page an external survey
  returns to (`/assignment/callback/:id`): in the app both would open as the app's
  own user.

  Both app IDs are listed on every environment: iOS only links a domain to an
  app whose Associated Domains entitlement names that domain, so the Dev app
  (`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
  and Prod builds share `co.eyra.next`.

  Serves the Digital Asset Links file (`assetlinks.json`) too, so the Next
  Android app can take its identity-provider sign-in back from the browser once
  it claims that callback. Android verifies a host for an app by its package and
  signing certificate, and has no team ID, so each environment vouches only for
  its own app: `ANDROID_APP_CERT_FINGERPRINTS` lists
  `<package>=<SHA-256 fingerprint>` per certificate (`config/runtime.exs` refuses
  a malformed entry). Without one, the file is not found.
  """
  use NextWeb, {:controller, [formats: [:json]]}

  @app_ids ["XNWQJGGM96.co.eyra.next", "XNWQJGGM96.co.eyra.next.dev"]

  def apple_app_site_association(conn, _params) do
    json(conn, %{webcredentials: %{apps: @app_ids}})
  end

  def assetlinks(conn, _params) do
    case Mica.Env.get(:android_app_links, []) do
      [] -> send_resp(conn, 404, "")
      links -> json(conn, statements(links))
    end
  end

  # One statement per package, with its fingerprints, in the order configured.
  defp statements(links) do
    links
    |> Enum.group_by(fn {package, _} -> package end, fn {_, fingerprint} -> fingerprint end)
    |> Enum.sort_by(fn {package, _} -> Enum.find_index(links, &(elem(&1, 0) == package)) end)
    |> Enum.map(fn {package, fingerprints} -> statement(package, Enum.uniq(fingerprints)) end)
  end

  defp statement(package, fingerprints) do
    %{
      relation: ["delegate_permission/common.handle_all_urls"],
      target: %{
        namespace: "android_app",
        package_name: package,
        sha256_cert_fingerprints: fingerprints
      }
    }
  end
end
