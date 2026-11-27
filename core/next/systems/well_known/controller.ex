defmodule Next.Systems.WellKnown.Controller do
  @moduledoc """
  Serves the apple-app-site-association file, so iOS opens invitation links
  (`/assignment/*`) in the Next app (UC-SENSE-03), and so the sign-in sheet may
  hand an identity-provider sign-in back to the app on this host
  (`webcredentials`, see `Next.Systems.Account.NativeHandoff`).

  Two kinds of `/assignment/` link are not among them, because they stay in the
  browser, where the participant is signed in; the app would open them as its own
  user:

    * a panel link's study: the panel link's entry (`/a/:sqid?p=…`) signs the
      panel participant in in the browser and sends them on to
      `/assignment/:id?via=affiliate` (`Systems.Affiliate.Controller`);
    * the page an external survey sends the participant back to,
      `/assignment/callback/:id`, which marks their task done.

  Both app IDs are listed on every environment: iOS only links a domain to an
  app whose Associated Domains entitlement names that domain, so the Dev app
  (`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
  and Prod builds share `co.eyra.next`.

  Serves the Digital Asset Links file (`assetlinks.json`) too, so Android opens
  those links in the Next Android app. Android verifies a host for an app by its
  package and signing certificate, and has no team ID, so each environment
  vouches only for its own app: `ANDROID_APP_CERT_FINGERPRINTS` lists
  `<package>=<SHA-256 fingerprint>` per certificate (`config/runtime.exs` refuses
  a malformed entry). Without one, the file is not found. The Android app itself
  hands the two browser links above back to the browser.
  """
  use NextWeb, {:controller, [formats: [:json]]}

  @app_ids ["XNWQJGGM96.co.eyra.next", "XNWQJGGM96.co.eyra.next.dev"]
  @components [
    %{"/" => "/assignment/callback/*", "exclude" => true},
    %{"/" => "/assignment/*", "?" => %{"via" => "affiliate"}, "exclude" => true},
    %{"/" => "/assignment/*"}
  ]

  def apple_app_site_association(conn, _params) do
    json(conn, %{
      applinks: %{details: [%{appIDs: @app_ids, components: @components}]},
      webcredentials: %{apps: @app_ids}
    })
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
