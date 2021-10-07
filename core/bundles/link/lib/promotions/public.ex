defmodule Link.Promotion.Public do
  @moduledoc """
  The public promotion screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.UI.Dialog
  use CoreWeb.Layouts.Website.Component, :promotion
  alias CoreWeb.Layouts.Website.Component, as: Website

  import CoreWeb.UI.Responsive.Viewport

  alias EyraUI.CampaignBanner
  alias EyraUI.Text.{Title1, Title2, BodyLarge}
  alias EyraUI.Button.{PrimaryLiveViewButton, BackButton}
  alias EyraUI.Hero.{HeroImage, HeroBanner}
  alias EyraUI.Card.Highlight

  alias Core.ImageHelpers
  alias Core.Promotions
  alias Core.Promotions.Promotion

  alias CoreWeb.{Devices, Languages}

  alias Link.Enums.Themes

  data(preview, :boolean)
  data(study, :any)
  data(promotion, :any)
  data(subtitle, :string)
  data(plugin, :any)
  data(plugin_info, :any)
  data(themes, :any)
  data(organisation, :any)
  data(image_info, :any, default: nil)
  data(back_path, :any)

  def mount(%{"id" => id, "preview" => preview, "back" => back}, _session, %{assigns: %{current_user: user}} = socket) do

    promotion = Promotions.get!(id)
    plugin = load_plugin(promotion)
    plugin_info = plugin.info(id, socket)

    themes = promotion |> Promotion.get_themes(Themes)
    organisation = promotion |> Promotion.get_organisation()

    observe(socket, promotion_updated: [promotion.id])

    {
      :ok,
      socket
      |> assign_viewport()
      |> assign(
        preview: preview == "true",
        user: user,
        promotion: promotion,
        themes: themes,
        organisation: organisation,
        back_path: back,
        plugin_info: plugin_info,
        plugin: plugin,
        dialog: nil
      )
      |> update_subtitle()
      |> update_image_info()
      |> update_menus()
    }
  end

  def mount(params, session, %{assigns: %{current_user: user}} = socket) do
    preview = Map.get(params, "preview", "false")
    back = Map.get(params, "back",
      if user.researcher do
        Routes.live_path(socket, Link.Dashboard)
      else
        Routes.live_path(socket, Link.Marketplace)
      end
    )

    mount(
      params
      |> Map.put("preview", preview)
      |> Map.put("back", back),
      session,
      socket
    )
  end


  defp update_image_info(%{assigns: %{viewport: %{"width" => 0}}} = socket), do: socket

  defp update_image_info(socket) do
    image_info = get_image_info(socket)
    socket |> assign(image_info: image_info)
  end

  defp update_subtitle(%{assigns: %{promotion: %{subtitle: nil}}} = socket) do
    assign(socket, subtitle: dgettext("eyra-promotion", "subtitle.label"))
  end

  defp update_subtitle(%{assigns: %{promotion: %{subtitle: subtitle}}} = socket) do
    assign(socket, subtitle: subtitle)
  end

  defp get_image_info(%{
         assigns: %{promotion: %{image_id: image_id}, viewport: %{"width" => viewport_width}}
       }) do
    image_width = viewport_width
    image_height = image_width * 0.75

    ImageHelpers.get_image_info(image_id, image_width, image_height)
  end

  def handle_observation(socket, :promotion_updated, promotion) do
    plugin = load_plugin(promotion)
    plugin_info = plugin.info(promotion.id, socket)

    themes = promotion |> Promotion.get_themes(Themes)
    organisation = promotion |> Promotion.get_organisation()

    socket
    |> assign(
      plugin_info: plugin_info,
      promotion: promotion,
      themes: themes,
      organisation: organisation
    )
    |> update_subtitle()
    |> update_image_info()
  end

  def load_plugin(%{plugin: plugin}) do
    plugins()[String.to_existing_atom(plugin)]
  end

  defp plugins, do: Application.fetch_env!(:core, :promotion_plugins)

  @impl true
  def handle_event("call-to-action", _params, %{assigns: %{preview: true}} = socket) do
    title = dgettext("eyra-promotion", "preview.inform.title")
    text = dgettext("eyra-promotion", "preview.inform.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event(
        "call-to-action",
        _params,
        %{assigns: %{promotion: promotion, plugin: plugin, plugin_info: plugin_info}} = socket
      ) do
    path = plugin.get_cta_path(promotion.id, plugin_info.call_to_action.target.value, socket)
    {:noreply, redirect(socket, external: path)}
  end

  @impl true
  def handle_event("call-to-action", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  @impl true
  def render(assigns) do
    ~H"""
      <Website
        user={{ @current_user}}
        user_agent={{ Browser.Ua.to_ua(@socket) }}
        menus={{ @menus }}
      >
        <template slot="hero">
          <HeroImage
            title={{@promotion.title}}
            subtitle={{@themes}}
            image_info={{@image_info}}
          >
            <template slot="call_to_action">
              <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
            </template>
          </HeroImage>
          <HeroBanner title={{@organisation.label}} subtitle={{ @plugin_info.byline }} icon_url={{ Routes.static_path(@socket, "/images/#{@organisation.id}.svg") }}/>
        </template>

        <div :if={{ show_dialog?(@dialog) }} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <Dialog vm={{ @dialog }} />
          </div>
        </div>

        <ContentArea>
            <MarginY id={{:page_top}} />
            <div class="ml-8 mr-8 text-center">
              <Title1>{{@subtitle}}</Title1>
            </div>

            <div class="mb-12 sm:mb-16" />
            <div class="grid gap-6 sm:gap-8 {{ grid_cols(Enum.count(@plugin_info.highlights)) }}">
              <div :for={{ highlight <- @plugin_info.highlights }} class="bg-grey5 rounded">
                <Highlight title={{highlight.title}} text={{highlight.text}} />
              </div>
            </div>
            <div class="mb-12 sm:mb-16" />

            <Title2 margin="">{{dgettext("eyra-promotion", "expectations.public.label")}}</Title2>
            <Spacing value="M" />
            <BodyLarge>{{ @promotion.expectations }}</BodyLarge>
            <Spacing value="M" />
            <Title2 margin="">{{dgettext("eyra-promotion", "description.public.label")}}</Title2>
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
            <div class="flex flex-col justify-center sm:flex-row gap-4 sm:gap-8 items-center">
              <Devices label={{ dgettext("eyra-promotion", "devices.available.label") }} devices={{ @plugin_info.devices }} />
              <Languages label={{ dgettext("eyra-promotion", "languages.available.label") }} languages={{ @plugin_info.languages }} />
            </div>
            <Spacing value="XL" />

            <PrimaryLiveViewButton label={{ @plugin_info.call_to_action.label }} event="call-to-action" />
            <Spacing value="M" />

            <div class="flex">
              <BackButton label={{ dgettext("eyra-promotion", "back.button.label") }} path={{ @back_path }}/>
            </div>
        </ContentArea>
      </Website>
    """
  end
end
