defmodule Core.Mailer.EmailLayoutView do
  use Phoenix.View, root: "lib/core/mailer/templates", namespace: Core.Mailer

  @scales ["", "@2x", "@3x"]
  def header_image_tag(name) do
    image_tag("header-#{name}")
  end

  def image_tag(image_name) do
    [{url, _} | _] =
      urls_with_scales =
      for scale <- @scales do
        url = "#{CoreWeb.Endpoint.static_url()}/images/email-#{image_name}#{scale}.png"
        {url, scale}
      end

    srcset =
      Enum.map_join(urls_with_scales, ",", fn {url, scale} ->
        "#{url} #{scale}"
      end)

    {:safe, ~s(<img class="#{image_name}" src="#{url}" srcset="#{srcset}">)}
  end
end
