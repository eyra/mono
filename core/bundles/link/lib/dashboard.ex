defmodule Link.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :dashboard

  alias Core.Studies
  alias CoreWeb.UI.ContentListItem
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Text.{Title2}
  alias Systems.NextAction
  alias Core.Content.Nodes
  alias Core.ImageHelpers

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [
      survey_tool: [promotion: [:content_node, :submission]],
      lab_tool: [promotion: [:content_node, :submission]]
    ]

    content_items =
      user
      |> Studies.list_owned_studies(preload: preload)
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

  def convert_to_vm(socket, %{
        updated_at: updated_at,
        survey_tool: %{
          id: edit_id,
          current_subject_count: current_subject_count,
          subject_count: target_subject_count,
          promotion: %{
            title: title,
            image_id: image_id,
            content_node: promotion_content_node,
            submission: %{
              status: status
            }
          }
        }
      }) do
    tag =
      case status do
        :idle ->
          %{text: dgettext("eyra-submission", "status.idle.label"), type: :warning}

        :submitted ->
          %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

        :accepted ->
          %{text: dgettext("eyra-submission", "status.accepted.label"), type: :success}
      end

    subtitle =
      case status do
        :idle ->
          if Nodes.ready?(promotion_content_node) do
            dgettext("eyra-submission", "ready.for.submission.message")
          else
            dgettext("eyra-submission", "incomplete.forms.message")
          end

        :submitted ->
          dgettext("eyra-submission", "waiting.for.coordinator.message")

        :accepted ->
          dgettext("link-dashboard", "quick_summary.%{subject_count}.%{target_subject_count}",
            subject_count: current_subject_count,
            target_subject_count: target_subject_count || 0
          )
      end

    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info }

    %{
      path: Routes.live_path(socket, Link.Survey.Content, edit_id),
      title: title,
      subtitle: subtitle || "<no subtitle>",
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end

  def convert_to_vm(socket, %{
        updated_at: updated_at,
        lab_tool: %{
          id: edit_id,
          promotion: %{
            title: title,
            image_id: image_id,
            content_node: promotion_content_node,
            submission: %{
              status: status
            }
          }
        }
      }) do
    label =
      case status do
        :idle ->
          %{text: dgettext("eyra-submission", "status.idle.label"), type: :warning}

        :submitted ->
          %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

        :accepted ->
          %{text: dgettext("eyra-submission", "status.accepted.label"), type: :success}
      end

    subtitle =
      case status do
        :idle ->
          if Nodes.ready?(promotion_content_node) do
            dgettext("eyra-submission", "ready.for.submission.message")
          else
            dgettext("eyra-submission", "incomplete.forms.message")
          end

        :submitted ->
          dgettext("eyra-submission", "waiting.for.coordinator.message")

        :accepted ->
          dgettext("link-dashboard", "quick_summary.%{subject_count}.%{target_subject_count}",
            subject_count: -1,
            target_subject_count: -1
          )
      end

    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info }

    %{
      path: Routes.live_path(socket, Link.Survey.Content, edit_id),
      title: title,
      subtitle: subtitle,
      label: label,
      level: :critical,
      image: image,
      quick_summary: quick_summery
    }
  end
end
