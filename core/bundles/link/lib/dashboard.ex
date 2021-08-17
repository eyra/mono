defmodule Link.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :dashboard

  alias Core.Studies
  alias CoreWeb.Components.ContentListItem
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{Title2}
  alias Core.NextActions.Live.NextActionHighlight
  alias Core.NextActions

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [survey_tool: [:promotion]]

    content_items =
      user
      |> Studies.list_owned_studies(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextActions.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-dashboard", "title") }}
        menus={{ build_menus(@socket, @current_user, :dashboard) }}
      >
        <ContentArea>
          <div :if={{ @next_best_action }} class="mb-6 md:mb-10">
            <NextActionHighlight vm={{ @next_best_action }}/>
          </div>
          <Title2>
            {{ dgettext("link-dashboard", "recent-items.title") }}
          </Title2>
          <ContentListItem :for={{item <- @content_items}} title={{item.title}} description="Facere dolorem sequi sit voluptas labore porro qui quis" quick_summary={{item.quick_summary}} status={{item.status}} image_id={{item.image_id}} to={{item.path}}  />
        </ContentArea>
      </Workspace>
    """
  end

  def convert_to_vm(socket, %{
        survey_tool: %{
          id: edit_id,
          current_subject_count: current_subject_count,
          subject_count: target_subject_count,
          promotion: %{
            title: title,
            description: description,
            image_id: image_id,
            published_at: published_at
          }
        }
      }) do
    status =
      if is_nil(published_at) do
        %{label: dgettext("link-dashboard", "status.concept"), color: "warning"}
      else
        %{label: dgettext("link-dashboard", "status.published"), color: "success"}
      end

    %{
      path: Routes.live_path(socket, Link.Survey.Content, edit_id),
      title: title,
      description: description,
      status: status,
      level: :critical,
      image_id: image_id,
      quick_summary:
        dgettext("link-dashboard", "quick_summary.%{subject_count}.%{target_subject_count}",
          subject_count: current_subject_count,
          target_subject_count: target_subject_count
        )
    }
  end
end
