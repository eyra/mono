defmodule Systems.Pool.CampaignsView do
  use CoreWeb.UI.LiveComponent

  import Frameworks.Utility.Guards

  alias Systems.{
    NextAction,
    Campaign,
    Assignment
  }

  alias Core.Accounts
  alias Core.ImageHelpers
  alias Core.Pools.Submission

  alias CoreWeb.UI.ContentList

  alias Frameworks.Pixel.Text.{Title2}

  prop(user, :any, required: true)

  data(submitted_campaigns, :list)
  data(accepted_campaigns, :list)

  def update(_params, socket) do
    clear_review_submission_next_action()

    preload = Campaign.Model.preload_graph(:full)

    submitted_campaigns =
      Campaign.Context.list_submitted_campaigns([Core.Survey.Tool], preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    accepted_campaigns =
      Campaign.Context.list_accepted_campaigns([Core.Survey.Tool], preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    {
      :ok,
      socket
      |> assign(submitted_campaigns: submitted_campaigns)
      |> assign(accepted_campaigns: accepted_campaigns)
    }
  end

  defp clear_review_submission_next_action do
    for user <- Accounts.list_pool_admins() do
      NextAction.Context.clear_next_action(user, Core.Pools.ReviewSubmission)
    end
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Case value={{ Enum.count(@submitted_campaigns) + Enum.count(@accepted_campaigns) > 0 }} >
          <True>
            <Title2>
              {{ dgettext("link-studentpool", "submitted.title") }}
              <span class="text-primary"> {{ Enum.count(@submitted_campaigns) }}</span>
            </Title2>
            <ContentList items={{@submitted_campaigns}} />
            <Spacing value="XL" />
            <Title2>
              {{ dgettext("link-studentpool", "accepted.title") }}
              <span class="text-primary"> {{ Enum.count(@accepted_campaigns) }}</span>
            </Title2>
            <ContentList items={{@accepted_campaigns}} />
          </True>
          <False>
            <Empty
              title={{ dgettext("link-studentpool", "campaigns.empty.title") }}
              body={{ dgettext("link-studentpool", "campaigns.empty.description") }}
              illustration="items"
            />
          </False>
        </Case>
      </ContentArea>
    """
  end

  defp convert_to_vm(socket, %{
         updated_at: updated_at,
         promotion: %{
           title: title,
           image_id: image_id,
           submission:
             %{
               id: submission_id,
               status: status
             } = submission
         },
         promotable_assignment:
           %{
             assignable_survey_tool: %{
               subject_count: target_subject_count
             }
           } = assignment
       } = campaign) do
    tag =
      case status do
        :submitted ->
          %{text: dgettext("link-studentpool", "status.submitted.label"), type: :delete}

        :accepted ->
          case Submission.published_status(submission) do
            :scheduled ->
              %{
                text: dgettext("link-studentpool", "status.accepted.scheduled.label"),
                type: :warning
              }

            :online ->
              %{
                text: dgettext("link-studentpool", "status.accepted.online.label"),
                type: :success
              }

            :closed ->
              %{
                text: dgettext("link-studentpool", "status.accepted.closed.label"),
                type: :disabled
              }
          end
      end

    target_subject_count = guard_nil(target_subject_count, :integer)

    open_spot_count = Assignment.Context.open_spot_count(assignment)

    subtitle_part1 = Campaign.Model.author_as_string(campaign)

    subtitle_part2 =
      if open_spot_count == target_subject_count do
        dgettext("link-studentpool", "sample.size",
          size: target_subject_count
        )
      else
        dgettext("link-studentpool", "spots.available",
          open: open_spot_count,
          total: target_subject_count
        )
      end

    subtitle = subtitle_part1 <> "  |  " <> subtitle_part2

    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: Routes.live_path(socket, Systems.Pool.SubmissionPage, submission_id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end


end
