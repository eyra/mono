defmodule Systems.Pool.Builders.CampaignItem do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext
  import Frameworks.Utility.Guards

  alias Core.ImageHelpers

  alias Systems.{
    Pool,
    Campaign,
    Assignment
  }

  def view_model(
        %{
          submission: %{id: submission_id, updated_at: updated_at} = submission,
          promotion: %{
            title: title,
            image_id: image_id
          },
          promotable:
            %{
              assignable_experiment: %{
                subject_count: target_subject_count
              }
            } = assignment
        } = campaign
      ) do
    tag = tag(submission)

    target_subject_count = guard_nil(target_subject_count, :integer)

    open_spot_count = Assignment.Public.open_spot_count(assignment)

    subtitle_part1 = Campaign.Model.author_as_string(campaign)

    subtitle_part2 =
      if open_spot_count == target_subject_count do
        dgettext("link-studentpool", "sample.size", size: target_subject_count)
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
      path: ~p"/pool/campaign/#{submission_id}",
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end

  defp tag(submission) do
    status = campaign_status(submission)
    text = Pool.CampaignStatus.translate(status)

    type =
      case status do
        :retracted -> :delete
        :submitted -> :tertiary
        :scheduled -> :warning
        :released -> :success
        :closed -> :disabled
        :completed -> :disabled
      end

    %{
      id: status,
      text: text,
      type: type
    }
  end

  defp campaign_status(submission) do
    case Pool.SubmissionModel.status(submission) do
      :accepted -> Pool.Public.published_status(submission)
      :idle -> :retracted
      :submitted -> :submitted
      :completed -> :completed
    end
  end
end
