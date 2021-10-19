defmodule Link.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :marketplace

  alias Systems.NextAction
  alias Systems.Campaign

  alias Core.ImageHelpers
  alias Core.Accounts
  alias Core.Pools.{Submission, Criteria}
  alias Core.Survey.Tool, as: SurveyTool
  alias Core.Lab.Tool, as: LabTool

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.ContentListItem

  alias Link.Marketplace.Card, as: CardVM

  alias EyraUI.Card.SecondaryStudy
  alias EyraUI.Text.{Title2}
  alias EyraUI.Grid.{DynamicGrid}

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

    preload = [
      survey_tool: [promotion: [submission: [:criteria]]],
      lab_tool: [:promotion, :time_slots]
    ]

    subject_campaigns =
      user
      |> Campaign.Context.list_subject_campaigns(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

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

  defp filter(studies, socket) when is_list(studies) do
    Enum.filter(studies, &filter(&1, socket))
  end

  defp filter(
         %{
           survey_tool: %{promotion: %{submission: %{criteria: submission_criteria} = submission}}
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

  def handle_info({:card_click, %{action: :public, id: id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Link.Promotion.Public, id))}
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
                <ContentListItem :for={{item <- @subject_campaigns}} vm={{item}} />
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
                    <SecondaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
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

  defp get_quick_summary(updated_at) do
    updated_at
    |> CoreWeb.UI.Timestamp.apply_timezone()
    |> CoreWeb.UI.Timestamp.humanize()
  end

  defp get_subtitle(
         _submission,
         _promotion_content_node,
         current_subject_count,
         target_subject_count
       ) do
    dgettext("link-dashboard", "quick_summary.%{subject_count}.%{target_subject_count}",
      subject_count: current_subject_count,
      target_subject_count: target_subject_count || 0
    )
  end

  def convert_to_vm(socket, %{
        id: id,
        updated_at: updated_at,
        survey_tool: %{
          id: edit_id,
          current_subject_count: current_subject_count,
          subject_count: target_subject_count,
          promotion: %{
            title: title,
            image_id: image_id,
            content_node: promotion_content_node,
            submission: submission
          }
        }
      }) do
    tag = Submission.get_tag(submission)

    subtitle =
      get_subtitle(
        submission,
        promotion_content_node,
        current_subject_count,
        target_subject_count
      )

    quick_summary = get_quick_summary(updated_at)
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      id: id,
      path: Routes.live_path(socket, Systems.Campaign.ContentPage, edit_id),
      title: title,
      subtitle: subtitle || "<no subtitle>",
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end
end
