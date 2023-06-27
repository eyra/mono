defmodule CoreWeb.UI.Language do
  use CoreWeb, :html

  attr(:redir, :string, required: true)

  def language(assigns) do
    [locale | _] = CoreWeb.Menu.Helpers.supported_languages()

    assigns =
      assigns
      |> assign(:locale_id, locale.id)
      |> assign(:locale_name, locale.name)

    ~H"""
    <a href={~p"/switch-language/#{@locale_id}?redir=#{@redir}"}>
      <img src={"/images/icons/#{@locale_id}.svg"} alt={"Switch language to #{@locale_name}"}/>
    </a>
    """
  end
end
