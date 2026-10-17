defmodule Next.WellKnown.System do
  @moduledoc "The `/.well-known` files of Next's domains, such as the iOS app-site association."
  use Core.System

  def override_routes do
    quote do
      scope "/", Next do
        get(
          "/.well-known/apple-app-site-association",
          WellKnownController,
          :apple_app_site_association
        )
      end
    end
  end
end
