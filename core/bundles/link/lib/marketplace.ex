defmodule Link.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :marketplace

  alias Systems.{
    NextAction,
    Campaign
  }

  alias Frameworks.Utility.ViewModelBuilder

  alias Core.Accounts
  alias Core.Pools.{Submission, Criteria}
  alias Core.Survey.Tool, as: SurveyTool
  alias Core.Lab.Tool, as: LabTool

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.ContentList

  alias Link.Marketplace.Card, as: CardVM

  alias Frameworks.Pixel.Card.SecondaryCampaign
  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Grid.{DynamicGrid}

  data(next_best_action, :any)
  data(highlighted_count, :any)
  data(owned_campaigns, :any)
  data(subject_campaigns, :any)
  data(subject_count, :any)
  data(available_campaigns, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    next_best_action = NextAction.Context.next_best_action(url_resolver(socket), user)
    user = socket.assigns[:current_user]

    preload = Campaign.Model.preload_graph(:full)

    subject_campaigns =
      user
      |> Campaign.Context.list_subject_campaigns(preload: preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, __MODULE__, user, url_resolver(socket)))

    highlighted_campaigns = subject_campaigns
    highlighted_count = Enum.count(subject_campaigns)

    exclusion_list =
      highlighted_campaigns
      |> Stream.map(fn campaign -> campaign.id end)
      |> Enum.into(MapSet.new())

    available_campaigns =
      Campaign.Context.list_accepted_campaigns([LabTool, SurveyTool],
        exclude: exclusion_list,
        preload: preload
      )
      |> filter(socket)
      |> Enum.map(&CardVM.primary_campaign(&1, socket))

    subject_count = Enum.count(subject_campaigns)
    available_count = Enum.count(available_campaigns)

    socket =
      socket
      |> update_menus()
      |> assign(next_best_action: next_best_action)
      |> assign(highlighted_count: highlighted_count)
      |> assign(subject_campaigns: subject_campaigns)
      |> assign(subject_count: subject_count)
      |> assign(available_campaigns: available_campaigns)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  defp filter(campaigns, socket) when is_list(campaigns) do
    Enum.filter(campaigns, &filter(&1, socket))
  end

  defp filter(
         %{
           promotion: %{submission: %{criteria: submission_criteria} = submission}
         },
         %{assigns: %{current_user: user}}
       ) do
    user_features = Accounts.get_features(user)

    online? = Submission.published_status(submission) == :online
    eligitable? = Criteria.eligitable?(submission_criteria, user_features)

    online? and eligitable?
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CoreWeb.Router.Helpers.live_path(socket, Systems.Campaign.ContentPage, id)
     )}
  end

  def handle_info(
        {:card_click, %{action: :public, id: id}},
        %{assigns: %{uri_path: uri_path}} = socket
      ) do
    promotion_path = Routes.live_path(socket, Systems.Promotion.LandingPage, id, back: uri_path)
    {:noreply, push_redirect(socket, to: promotion_path)}
  end

  @impl true
  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
  end

  def render_empty?(%{available_count: available_count}) do
    not feature_enabled?(:marketplace) or available_count == 0
  end

  def render(assigns) do
    ~H"""
        <Workspace
          title={{ dgettext("eyra-ui", "marketplace.title") }}
          menus={{ @menus }}
        >
          <ContentArea>
            <MarginY id={{:page_top}} />
            <div :if={{ @next_best_action }}>
              <NextAction.HighlightView vm={{ @next_best_action }}/>
              <div class="mt-6 lg:mt-10"/>
            </div>
            <Case value={{ @subject_count > 0 }} >
              <True>
                <Title2>
                  {{ dgettext("eyra-campaign", "campaign.subject.title") }}
                  <span class="text-primary"> {{ @subject_count }}</span>
                </Title2>
                <ContentList items={{@subject_campaigns}} />
              </True>
            </Case>
            <Case value={{ render_empty?(assigns) }} >
              <False>
                <Spacing :if={{ @subject_count > 0 }} value="XL" />
                <Title2>
                  {{ dgettext("eyra-campaign", "campaign.all.title") }}
                  <span class="text-primary"> {{ @available_count }}</span>
                </Title2>
                <DynamicGrid>
                  <div :for={{ card <- @available_campaigns  }} class="mb-1" >
                    <SecondaryCampaign conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
                  </div>
                </DynamicGrid>
              </False>
              <True>
                <Spacing :if={{ @subject_count > 0 }} value="XXL" />
                <Empty
                  title={{ dgettext("eyra-marketplace", "empty.title") }}
                  body={{ dgettext("eyra-marketplace", "empty.description") }}
                  illustration="cards"
                />
              </True>
            </Case>
          </ContentArea>
        </Workspace>
    """
  end
end
