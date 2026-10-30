defmodule Next.Systems.WellKnown.System do
  @moduledoc "The `/.well-known` files of Next's domains, such as the iOS app-site association."
  use Mica.System

  def override_routes do
    quote do
      scope "/", Next.Systems do
        get(
          "/.well-known/apple-app-site-association",
          WellKnown.Controller,
          :apple_app_site_association
        )
      end
    end
  end
end
