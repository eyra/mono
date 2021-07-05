defmodule CoreWeb.Promotion.Public do
  @moduledoc """
  The public promotion screen.
  """
  use CoreWeb, :live_view

  alias EyraUI.Spacing
  alias EyraUI.CampaignBanner
  alias EyraUI.Panel.Panel
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title2, Title3, BodyLarge, Intro}
  alias EyraUI.Button.{PrimaryLiveViewButton, SecondaryLiveViewButton, BackButton}
  alias EyraUI.Hero.{HeroImage, HeroBanner}
  alias EyraUI.Card.Highlight

  alias Core.ImageHelpers
  alias Core.Promotions
  alias Core.Promotions.Promotion

  alias CoreWeb.Devices

  data(study, :any)
  data(promotion, :any)
  data(plugin, :any)
  data(plugin_info, :any)
  data(transient, :any)

  @plugins %{
    "data_donation" => CoreWeb.DataDonation.PromotionPlugin,
    "survey" => CoreWeb.Survey.PromotionPlugin
  }

  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    promotion = Promotions.get!(id)
    plugin = load_plugin(promotion)
    plugin_info = plugin.info(id, socket)

    transient = %{
      image_info: ImageHelpers.get_image_info(promotion.image_id, 2560, 1920),
      themes: promotion |> Promotion.get_themes(),
      organisation: promotion |> Promotion.get_organisation()
    }

    {
      :ok,
      socket
      |> assign(
        user: user,
        promotion: promotion,
        transient: transient,
        plugin_info: plugin_info,
        plugin: plugin
      )
    }
  end

  def load_plugin(%{plugin: plugin}) do
    @plugins[plugin]
  end

  def handle_event(
        "call-to-action",
        _params,
        %{assigns: %{promotion: promotion, plugin: plugin, plugin_info: plugin_info}} = socket
      ) do
    path = plugin.get_cta_path(promotion.id, plugin_info.call_to_action.target.value, socket)
    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_event("call-to-action", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroImage
        title={{@promotion.title}}
        subtitle={{@transient.themes}}
        image_info={{@transient.image_info}}
      >
        <template slot="call_to_action">
          <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
        </template>
      </HeroImage>
      <HeroBanner title={{@transient.organisation.label}} subtitle={{ @plugin_info.byline }} icon_url={{ Routes.static_path(@socket, "/images/#{@transient.organisation.id}.svg") }}/>
      <ContentArea>
          <div class="ml-8 mr-8 text-center">
            <Title1>{{@promotion.subtitle}}</Title1>
          </div>

          <div class="mb-12 sm:mb-16" />
          <div class="grid grid-cols-1 gap-6 sm:gap-8 sm:grid-cols-{{ Enum.count(@plugin_info.highlights) }}">
            <div :for={{ highlight <- @plugin_info.highlights }} class="bg-grey5 rounded">
              <Highlight title={{highlight.title}} text={{highlight.text}} />
            </div>
          </div>
          <div class="mb-12 sm:mb-16" />

          <Title2>{{dgettext("eyra-survey", "expectations.public.label")}}</Title2>
          <Spacing value="M" />
          <BodyLarge>{{ @promotion.expectations }}</BodyLarge>
          <Spacing value="M" />
          <Title2>{{dgettext("eyra-survey", "description.public.label")}}</Title2>
          <Spacing value="M" />
          <BodyLarge>{{ @promotion.description }}</BodyLarge>
          <Spacing value="L" />

          <CampaignBanner
            photo_url={{@promotion.banner_photo_url}}
            placeholder_photo_url={{ Routes.static_path(@socket, "/images/profile_photo_default.svg") }}
            title={{@promotion.banner_title}}
            subtitle={{@promotion.banner_subtitle}}
            url={{@promotion.banner_url}}
          />
          <Spacing value="L" />
          <Panel bg_color="bg-grey5" align="text-center">
            <template slot="title">
              <Title3>{{ dgettext("eyra-promotion", "keep.me.updated.title") }}</Title3>
            </template>
            <Intro>{{ dgettext("eyra-promotion", "keep.me.updated.text") }}</Intro>
            <Spacing value="M" />
            <SecondaryLiveViewButton label={{ dgettext("eyra-promotion", "keep.me.updated.button.label") }} event="register" color="text-primary"/>
          </Panel>

          <Spacing value="L" />
          <Devices label={{ dgettext("eyra-promotion", "devices.available.label") }} devices={{ @plugin_info.devices }}/>
          <Spacing value="XL" />

          <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
          <Spacing value="M" />

          <div class="flex">
            <BackButton label={{ dgettext("eyra-promotion", "back.button.label") }} path={{ Routes.live_path(@socket, CoreWeb.Dashboard) }}/>
          </div>
      </ContentArea>
    """
  end
end
