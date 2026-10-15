defmodule Systems.Email.EmailLayoutHTML do
  use Phoenix.Component

  embed_templates("email_layout/*.html", suffix: "_html")
  embed_templates("email_layout/*.text", suffix: "_text")

  # Define layout template functions for bamboo_phoenix 2.0
  # Returns whatever the embedded templates return naturally
  # bamboo_phoenix will handle the normalization
  def email("html", assigns) do
    email_html(assigns)
  end

  def email("text", assigns) do
    email_text(assigns)
  end

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
