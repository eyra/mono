defmodule Next.Systems.WellKnown.System do
  @moduledoc """
  The `/.well-known` files of Next's domains: the iOS app-site association and
  the Android Digital Asset Links.
  """
  use Mica.System

  def override_routes do
    quote do
      scope "/", Next.Systems do
        get(
          "/.well-known/apple-app-site-association",
          WellKnown.Controller,
          :apple_app_site_association,
          as: :well_known
        )

        get("/.well-known/assetlinks.json", WellKnown.Controller, :assetlinks, as: :well_known)
      end
    end
  end
end
