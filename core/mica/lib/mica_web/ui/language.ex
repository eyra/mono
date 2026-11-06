defmodule MicaWeb.UI.Language do
  use MicaWeb, :ui

  attr(:redir, :string, required: true)

  def language(assigns) do
    [locale | _] = MicaWeb.Menu.Helpers.supported_languages()

    assigns =
      assigns
      |> assign(:locale_id, locale.id)
      |> assign(:locale_name, locale.name)
      |> assign(:icon, "#{locale.id}.svg")

    ~H"""
    <a href={~p"/switch-language/#{@locale_id}?redir=#{@redir}"}>
      <img src={~p"/images/icons/#{@icon}"} alt={"Switch language to #{@locale_name}"}/>
    </a>
    """
  end
end
