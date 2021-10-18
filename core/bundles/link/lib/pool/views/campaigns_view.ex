defmodule Link.Pool.CampaignsView do
  use CoreWeb.UI.LiveComponent

  import Frameworks.Utility.Guards

  alias Systems.NextAction

  alias Core.Studies
  alias Core.Accounts
  alias Core.ImageHelpers
  alias Core.Pools.Submission

  alias CoreWeb.UI.ContentListItem

  alias EyraUI.Text.{Title2}

  prop(user, :any, required: true)

  data(submitted_studies, :list)
  data(accepted_studies, :list)

  def update(_params, socket) do
    clear_review_submission_next_action()

    preload = [
      survey_tool: [promotion: [:content_node, :submission]]
    ]

    submitted_studies =
      Studies.list_submitted_studies([Core.Survey.Tool], preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    accepted_studies =
      Studies.list_accepted_studies([Core.Survey.Tool], preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    {
      :ok,
      socket
      |> assign(submitted_studies: submitted_studies)
      |> assign(accepted_studies: accepted_studies)
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
        <Case value={{ Enum.count(@submitted_studies) + Enum.count(@accepted_studies) > 0 }} >
          <True>
            <Title2>
              {{ dgettext("link-studentpool", "submitted.title") }}
              <span class="text-primary"> {{ Enum.count(@submitted_studies) }}</span>
            </Title2>
            <ContentListItem :for={{item <- @submitted_studies}} vm={{item}} />
            <Spacing value="XL" />
            <Title2>
              {{ dgettext("link-studentpool", "accepted.title") }}
              <span class="text-primary"> {{ Enum.count(@accepted_studies) }}</span>
            </Title2>
            <ContentListItem :for={{item <- @accepted_studies}} vm={{item}} />
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
         survey_tool: %{
           current_subject_count: current_subject_count,
           subject_count: target_subject_count,
           promotion: %{
             title: title,
             image_id: image_id,
             submission:
               %{
                 id: submission_id,
                 status: status
               } = submission
           }
         }
       }) do
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
    current_subject_count = guard_nil(current_subject_count, :integer)

    open_spots = target_subject_count - current_subject_count

    subtitle =
      dgettext("link-studentpool", "spots.available",
        open: open_spots,
        total: target_subject_count
      )

    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: Routes.live_path(socket, Link.Pool.SubmissionPage, submission_id),
      title: title,
      subtitle: subtitle || "<no subtitle>",
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end
end
