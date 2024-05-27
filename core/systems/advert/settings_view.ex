defmodule Systems.Advert.SettingsView do
  use CoreWeb, :live_component
  require Systems.Advert.Themes

  alias Systems.Advert
  alias Systems.Promotion

  @impl true
  def update(%{advert: advert}, socket) do
    {
      :ok,
      socket
      |> assign(advert: advert)
      |> compose_child(:promotion_form)
    }
  end

  @impl true
  def compose(:promotion_form, %{advert: %{promotion: promotion}}) do
    %{
      module: Promotion.FormView,
      params: %{
        entity: promotion,
        themes_module: Advert.Themes
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-advert", "settings.title") %></Text.title2>
          <.spacing value="M" />
          <.child name={:promotion_form} fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
