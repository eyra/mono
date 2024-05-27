defmodule Systems.Advert.PromotionLandingPageBuilder do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  alias Phoenix.LiveView

  alias Systems.Advert
  alias Systems.Promotion
  alias Systems.Assignment

  def view_model(
        %Advert.Model{
          id: id,
          submission:
            %{
              pool: %{name: pool_name}
            } = submission,
          promotion: promotion,
          assignment:
            %{
              info: %{logo_url: logo_url} = info
            } = assignment
        } = advert,
        _assigns
      ) do
    assignment
    |> Assignment.Model.language()
    |> CoreWeb.LiveLocale.put_locale()

    extra = Map.take(promotion, [:image_id | Promotion.Model.plain_fields()])
    icon_url = "/images/#{pool_name |> String.downcase()}-wide-dark.svg"

    %{
      id: id,
      icon_url: icon_url,
      logo_url: logo_url,
      themes: themes(promotion),
      highlights: highlights(assignment, submission),
      call_to_action: apply_call_to_action(advert),
      language: Assignment.Model.language(assignment),
      devices: Assignment.InfoModel.devices(info),
      active_menu_item: :projects
    }
    |> Map.merge(extra)
  end

  defp themes(%{themes: themes}, themes_module \\ Advert.Themes) do
    themes
    |> themes_module.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map_join(", ", & &1.value)
  end

  defp highlights(assignment, submission) do
    [
      Advert.Builders.Highlight.view_model(submission, :reward),
      Advert.Builders.Highlight.view_model(assignment, :duration),
      Advert.Builders.Highlight.view_model(assignment, :status)
    ]
  end

  defp apply_call_to_action(advert) do
    %{
      label: dgettext("eyra-advert", "promotion.apply.button"),
      target: %{type: :event, value: "apply"},
      advert: advert,
      handle: &handle_apply/1
    }
  end

  def handle_apply(
        %{
          assigns: %{
            vm: %{call_to_action: %{advert: %{promotion: promotion, assignment: %{id: id}}}}
          }
        } = socket
      ) do
    Promotion.Private.log_performance_event(promotion, :clicks)
    LiveView.push_redirect(socket, to: ~p"/assignment/#{id}/apply")
  end
end
