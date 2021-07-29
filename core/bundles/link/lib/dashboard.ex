defmodule Link.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  import Ecto

  alias Core.Studies
  alias CoreWeb.Components.ContentListItem

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{Title2}

  data(content_items, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [survey_tool: [:promotion]]

    content_items =
      user
      |> Studies.list_owned_studies(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> assign(content_items: content_items)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("link-dashboard", "title") }} />
      <ContentArea>
        <Title2>
          {{ dgettext("link-dashboard", "recent-items.title") }}
        </Title2>
        <ContentListItem :for={{item <- @content_items}} title={{item.title}} description="Facere dolorem sequi sit voluptas labore porro qui quis" quick_summary={{item.quick_summary}} status={{item.status}} level={{:critical}} image_id={{item.image_id}} to={{item.path}}  />
      </ContentArea>
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
        %{label: dgettext("link-dashboard", "status.concept"), color: "tertiary"}
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
