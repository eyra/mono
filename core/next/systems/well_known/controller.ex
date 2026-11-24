defmodule Next.Systems.WellKnown.Controller do
  @moduledoc """
  Serves the apple-app-site-association file, so iOS opens invitation links
  (`/assignment/*`) in the Next app (UC-SENSE-03), and so the sign-in sheet may
  hand an identity-provider sign-in back to the app on this host
  (`webcredentials`, see `Next.Systems.Account.NativeHandoff`).

  Both app IDs are listed on every environment: iOS only links a domain to an
  app whose Associated Domains entitlement names that domain, so the Dev app
  (`co.eyra.next.dev`) never claims links on other environments. Local, Staging,
  and Prod builds share `co.eyra.next`.

  Serves the Digital Asset Links file (`assetlinks.json`) too, so Android opens
  those links in the Next Android app. Every package is
  listed on every environment: Android only verifies a domain for an app whose
  manifest names that domain. The fingerprints of the certificates the apps are
  signed with come from `ANDROID_APP_CERT_FINGERPRINTS` (separated by commas or
  whitespace); without a well-formed one the file is not found.
  """
  use NextWeb, {:controller, [formats: [:json]]}

  @app_ids ["XNWQJGGM96.co.eyra.next", "XNWQJGGM96.co.eyra.next.dev"]
  @android_packages ["co.eyra.next", "co.eyra.next.dev", "co.eyra.next.staging"]
  @fingerprint ~r/\A[0-9A-F]{2}(:[0-9A-F]{2}){31}\z/

  def apple_app_site_association(conn, _params) do
    json(conn, %{
      applinks: %{details: [%{appIDs: @app_ids, components: [%{"/" => "/assignment/*"}]}]},
      webcredentials: %{apps: @app_ids}
    })
  end

  def assetlinks(conn, _params) do
    case fingerprints(Mica.Env.get(:android_app_cert_fingerprints, "")) do
      [] -> send_resp(conn, 404, "")
      fingerprints -> json(conn, Enum.map(@android_packages, &statement(&1, fingerprints)))
    end
  end

  defp fingerprints(value) do
    value
    |> String.upcase()
    |> String.split([",", " ", "\t", "\n", "\r"], trim: true)
    |> Enum.filter(&Regex.match?(@fingerprint, &1))
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
