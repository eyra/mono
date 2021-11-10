defmodule Link.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :dashboard

  alias Systems.{
    Campaign,
    Crew
  }

  alias Core.Content.Nodes
  alias Core.ImageHelpers
  alias Core.Pools.Submission
  alias CoreWeb.UI.ContentListItem
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Text.{Title2}
  alias Systems.NextAction

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    content_items =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextAction.Context.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-dashboard", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <div :if={{ @next_best_action }} class="mb-6 md:mb-10">
            <NextAction.HighlightView vm={{ @next_best_action }}/>
          </div>
          <Case value={{ Enum.count(@content_items) > 0 }} >
            <True>
              <Title2>
                {{ dgettext("link-dashboard", "recent-items.title") }}
              </Title2>
              <ContentListItem :for={{item <- @content_items}} vm={{item}} />
            </True>
            <False>
              <Empty
                title={{ dgettext("eyra-dashboard", "empty.title") }}
                body={{ dgettext("eyra-dashboard", "empty.description") }}
                illustration="items"
              />
            </False>
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
         submission,
         promotion_content_node,
         current_subject_count,
         target_subject_count
       ) do
    case submission.status do
      :idle ->
        if Nodes.ready?(promotion_content_node) do
          dgettext("eyra-submission", "ready.for.submission.message")
        else
          dgettext("eyra-submission", "incomplete.forms.message")
        end

      :submitted ->
        dgettext("eyra-submission", "waiting.for.coordinator.message")

      :accepted ->
        case Submission.published_status(submission) do
          :scheduled ->
            dgettext("eyra-submission", "accepted.scheduled.message")

          :online ->
            dgettext("link-dashboard", "quick_summary.%{subject_count}.%{target_subject_count}",
              subject_count: target_subject_count - current_subject_count,
              target_subject_count: target_subject_count
            )

          :closed ->
            dgettext("eyra-submission", "accepted.closed.message")
        end
    end
  end

  def convert_to_vm(socket, %{
        updated_at: updated_at,
        promotion: %{
          title: title,
          image_id: image_id,
          content_node: promotion_content_node,
          submission: submission
        },
        promotable_assignment: %{
          crew: crew,
          assignable_survey_tool: %{
            id: edit_id,
            subject_count: target_subject_count
          }
        }
      }) do
    tag = Submission.get_tag(submission)

    target_subject_count =
      if target_subject_count == nil do
        0
      else
        target_subject_count
      end

    current_subject_count = Crew.Context.count_tasks(crew, [:pending, :completed])

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
      path: Routes.live_path(socket, Systems.Campaign.ContentPage, edit_id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end

  def convert_to_vm(socket, %{
        updated_at: updated_at,
        promotion: %{
          title: title,
          image_id: image_id,
          content_node: promotion_content_node,
          submission: submission
        },
        promotable_assignment: %{
          assignabel_lab_tool: %{
            id: edit_id
          }
        }
      }) do
    tag = Submission.get_tag(submission)
    subtitle = get_subtitle(submission, promotion_content_node, -1, -1)
    quick_summery = get_quick_summary(updated_at)
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: Routes.live_path(socket, Systems.Campaign.ContentPage, edit_id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end
end
