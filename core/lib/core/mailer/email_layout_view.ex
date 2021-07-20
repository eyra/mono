defmodule Core.Mailer.EmailLayoutView do
  use Phoenix.View, root: "lib/core/mailer/templates", namespace: Core.Mailer

  @scales ["", "@2x", "@3x"]

  def image_tag(image_name) do
    [{url, _} | _] =
      urls_with_scales =
      for scale <- @scales do
        url = "#{CoreWeb.Endpoint.static_url()}/email-#{image_name}#{scale}.png"
        {url, scale}
      end

    srcset =
      urls_with_scales
      |> Enum.map(fn {url, scale} ->
        "#{url} #{scale}"
      end)
      |> Enum.join(",")

    {:safe, ~s(<img class="#{image_name}" src="#{url}" srcset="#{srcset}">)}
  end
end
