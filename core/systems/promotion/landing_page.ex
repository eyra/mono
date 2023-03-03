defmodule Systems.Promotion.LandingPage do
  @moduledoc """
  The public promotion screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.UI.PlainDialog
  use CoreWeb.Layouts.Website.Component, :promotion
  alias CoreWeb.Layouts.Website.Component, as: Website

  import CoreWeb.UI.Responsive.Viewport

  alias Frameworks.Pixel.CampaignBanner
  alias Frameworks.Pixel.Text.{Title1, Title2, BodyLarge}
  alias Frameworks.Pixel.Button.{PrimaryLiveViewButton, BackButton}
  alias Frameworks.Pixel.Hero.{HeroImage, HeroBanner}
  alias Frameworks.Pixel.Card.Highlight

  alias Core.ImageHelpers
  alias Core.Accounts

  alias CoreWeb.{Devices, Languages}

  alias Systems.{
    Promotion
  }

  data(preview, :boolean)
  data(model, :map)
  data(image_info, :map)
  data(back_path, :any)

  def mount(
        %{"id" => id, "preview" => preview, "back" => back},
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    model = Promotion.Public.get!(id)

    {
      :ok,
      socket
      |> assign_viewport()
      |> assign(
        model: model,
        preview: preview == "true",
        user: user,
        back_path: back,
        dialog: nil,
        image_info: nil
      )
      |> observe_view_model()
      |> update_image_info()
      |> update_menus()
    }
  end

  def mount(params, session, %{assigns: %{current_user: user}} = socket) do
    preview = Map.get(params, "preview", "false")

    back =
      params
      |> Map.get("back", Routes.live_path(socket, Accounts.start_page_target(user)))

    mount(
      params
      |> Map.put("preview", preview)
      |> Map.put("back", back),
      session,
      socket
    )
  end

  defp update_image_info(%{assigns: %{viewport: %{"width" => 0}}} = socket), do: socket

  defp update_image_info(
         %{assigns: %{viewport: %{"width" => viewport_width}, vm: %{image_id: image_id}}} = socket
       ) do
    image_width = viewport_width
    image_height = image_width * 0.75
    image_info = ImageHelpers.get_image_info(image_id, image_width, image_height)

    socket
    |> assign(image_info: image_info)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
    |> update_image_info()
    |> update_menus()
  end

  @impl true
  def handle_event("call-to-action-1", params, socket) do
    handle_event("call-to-action", params, socket)
  end

  @impl true
  def handle_event("call-to-action-2", params, socket) do
    handle_event("call-to-action", params, socket)
  end

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
        %{assigns: %{vm: %{call_to_action: %{handle: handle}}}} = socket
      ) do
    {:noreply, handle.(socket)}
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
    ~F"""
    <Website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus}>
      <:hero>
        <HeroImage title={@vm.title} subtitle={@vm.themes} image_info={@image_info}>
          <:call_to_action>
            <PrimaryLiveViewButton label={@vm.call_to_action.label} event="call-to-action-1" />
          </:call_to_action>
        </HeroImage>
        <HeroBanner
          title={@vm.organisation.label}
          subtitle={@vm.byline}
          icon_url={CoreWeb.Endpoint.static_path("/images/#{@vm.organisation.id}.svg")}
        />
      </:hero>

      <div
        :if={show_dialog?(@dialog)}
        class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog {...@dialog} />
        </div>
      </div>

      <ContentArea>
        <MarginY id={:page_top} />
        <div class="ml-8 mr-8 text-center">
          <Title1>{@vm.subtitle}</Title1>
        </div>

        <div class="mb-12 sm:mb-16" />
        <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
          <div :for={highlight <- @vm.highlights} class="bg-grey5 rounded">
            <Highlight title={highlight.title} text={highlight.text} />
          </div>
        </div>
        <div class="mb-12 sm:mb-16" />

        <Title2 margin="">{dgettext("eyra-promotion", "expectations.public.label")}</Title2>
        <Spacing value="M" />
        <BodyLarge>{@vm.expectations}</BodyLarge>
        <Spacing value="M" />
        <Title2 margin="">{dgettext("eyra-promotion", "description.public.label")}</Title2>
        <Spacing value="M" />
        <BodyLarge>{@vm.description}</BodyLarge>
        <Spacing value="L" />

        <CampaignBanner
          photo_url={@vm.banner_photo_url}
          placeholder_photo_url={CoreWeb.Endpoint.static_path("/images/profile_photo_default.svg")}
          title={@vm.banner_title}
          subtitle={@vm.banner_subtitle}
          url={@vm.banner_url}
        />
        <Spacing value="L" />
        <div class="flex flex-col justify-center sm:flex-row gap-4 sm:gap-8 items-center">
          <Devices label={dgettext("eyra-promotion", "devices.available.label")} devices={@vm.devices} />
          <Languages
            label={dgettext("eyra-promotion", "languages.available.label")}
            languages={@vm.languages}
          />
        </div>
        <Spacing value="XL" />

        <PrimaryLiveViewButton label={@vm.call_to_action.label} event="call-to-action-2" />
        <Spacing value="M" />

        <div class="flex">
          <BackButton label={dgettext("eyra-promotion", "back.button.label")} path={@back_path} />
        </div>
      </ContentArea>
    </Website>
    """
  end
end
