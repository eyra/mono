defmodule Systems.Campaign.OverviewPage do
  @moduledoc """
   The recruitment page for researchers.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :recruitment

  alias Systems.Campaign

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Frameworks.Pixel.Button.PrimaryLiveViewButton

  alias Link.Marketplace.Card, as: CardVM
  alias Frameworks.Pixel.Card.DynamicCampaign
  alias Frameworks.Pixel.Grid.DynamicGrid
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Button.Action.Send
  alias Frameworks.Pixel.Button.Face.Forward

  data(campaigns, :map, default: [])

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    campaigns =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      # Temp: only survey tools for now
      |> Enum.filter(& &1.promotable_assignment.assignable_survey_tool)
      |> Enum.map(&CardVM.campaign_researcher(&1, socket))

    {:ok,
     socket
     |> assign(campaigns: campaigns)
     |> update_menus()}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("create_campaign", _params, socket) do
    tool = create_campaign(socket)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Campaign.ContentPage, tool.id))}
  end

  @impl true
  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Campaign.ContentPage, id))}
  end

  defp create_campaign(%{assigns: %{current_user: user}} = _socket) do
    title = dgettext("eyra-dashboard", "default.study.title")
    Campaign.Assembly.create(user, title)
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-survey", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <Case value={{ Enum.count(@campaigns) > 0 }} >
          <True>
            <div class="flex flex-row items-center">
              <div class="h-full">
                <Title2 margin="">{{ dgettext("link-survey", "campaign.overview.title") }}</Title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Send vm={{ %{event: "create_campaign" } }}>
                  <div class="sm:hidden">
                    <Forward vm={{ label: dgettext("link-survey", "add.new.button.short") }} />
                  </div>
                  <div class="hidden sm:block">
                    <Forward vm={{ label: dgettext("link-survey", "add.new.button") }} />
                  </div>
                </Send>
              </div>
            </div>
            <MarginY id={{:title2_bottom}} />
            <DynamicGrid>
              <div :for={{ campaign <- @campaigns  }} >
                <DynamicCampaign conn={{@socket}} path_provider={{Routes}} card={{campaign}} click_event_data={{%{action: :edit, id: campaign.edit_id } }} />
              </div>
            </DynamicGrid>
            <Spacing value="L" />
          </True>
          <False>
            <Empty
              title={{ dgettext("link-survey", "empty.title") }}
              body={{ dgettext("link-survey", "empty.description") }}
              illustration="cards"
            />
            <Spacing value="L" />
            <PrimaryLiveViewButton label={{ dgettext("link-survey", "add.first.button") }} event="create_campaign"/>
          </False>
          </Case>
        </ContentArea>
      </Workspace>
    """
  end
end
