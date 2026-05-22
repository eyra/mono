defmodule Systems.Advert.SettingsView do
  use CoreWeb, :live_component
  require Systems.Advert.Themes

  alias Systems.Advert
  alias Systems.Affiliate
  alias Systems.Promotion

  @impl true
  def update(%{advert: advert}, socket) do
    {
      :ok,
      socket
      |> assign(advert: advert)
      |> assign_invite_url()
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

  defp assign_invite_url(%{assigns: %{advert: %{promotion_id: promotion_id}}} = socket) do
    path = ~p"/promotion/#{promotion_id}"
    url = (Application.get_env(:core, :base_url) || "") <> path

    assign(socket,
      invite_title: dgettext("eyra-advert", "settings.invite.title"),
      invite_annotation: dgettext("eyra-advert", "settings.invite.annotation"),
      invite_url: url
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-advert", "settings.title") %></Text.title2>
          <.spacing value="M" />
          <Affiliate.Html.url_panel
            title={@invite_title}
            annotation={@invite_annotation}
            url={@invite_url}
          />
          <.spacing value="L" />
          <.child name={:promotion_form} fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
