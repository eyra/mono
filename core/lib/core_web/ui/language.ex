defmodule CoreWeb.UI.Language do
  use CoreWeb, :html

  attr(:redir, :string, required: true)

  def language(assigns) do
    [locale | _] = CoreWeb.Menu.Helpers.supported_languages()

    assigns =
      assigns
      |> assign(:locale_id, locale.id)
      |> assign(:locale_name, locale.name)
      |> assign(:icon, "#{locale.id}.svg")

    ~H"""
    <a href={~p"/switch-language/#{@locale_id}?redir=#{@redir}"}>
      <img src={~p"/images/icons" <> "/#{@icon}"} alt={"Switch language to #{@locale_name}"}/>
    </a>
    """
  end
end
