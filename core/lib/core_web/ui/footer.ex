defmodule CoreWeb.UI.Footer do
  use CoreWeb, :html

  attr(:left, :any, default: "footer-left.svg")
  attr(:right, :any, default: "footer-right.svg")

  def content_footer(assigns) do
    ~H"""
    <div class="h-footer sm:h-footer-sm lg:h-footer-lg">
      <div class="flex">
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={~p"/images/#{@left}"} alt=""/>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={~p"/images/#{@right}"} alt="" />
        </div>
      </div>
    </div>
    """
  end

  defp to_link({text, href}) do
    "<a class=\"text-primary\" href=\"#{href}\" target=\"_blank\">#{text}</a>"
  end

  def platform_footer(assigns) do
    privacy_text = dgettext("eyra-ui", "privacy.link")
    privacy_url = "https://eyra.notion.site/Privacy-Policy-7acb32ac39514d68aa4d1b69717d0752"
    terms_text = dgettext("eyra-ui", "terms.link")
    terms_url = "https://eyra.notion.site/Terms-of-Service-059c9ffa2ac044a9a888b2bc7fe7bf1c"
    eyra_url = "https://eyra.co"

    left_elements =
      [
        {privacy_text, privacy_url},
        {terms_text, terms_url}
      ]
      |> Enum.map(&to_link/1)

    eyra_element = "Powered by #{to_link({"Eyra", eyra_url})}"

    content =
      (left_elements ++ [eyra_element])
      |> Enum.join("<span class=\"whitespace-pre-wrap\">  |  </span>")

    assigns = assign(assigns, content: content)

    ~H"""
      <div class="w-full h-platform-footer-height flex flex-row items-center justify-center">
        <Text.footnote>
          <%= raw(@content) %>
        </Text.footnote>
      </div>
    """
  end
end
