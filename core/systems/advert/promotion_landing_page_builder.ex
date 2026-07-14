defmodule Systems.Advert.PromotionLandingPageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Phoenix.LiveView

  alias Systems.Advert
  alias Systems.Pool
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
    |> CoreWeb.Live.Hook.Locale.put_locale()

    extra = Map.take(promotion, [:image_id | Promotion.Model.plain_fields()])
    icon_url = "/images/logos/products/#{String.downcase(pool_name)}_wide.svg"

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
      Advert.Builders.Highlight.view_model({submission, assignment}, :reward),
      Advert.Builders.Highlight.view_model(assignment, :duration),
      Advert.Builders.Highlight.view_model(assignment, :status)
    ]
  end

  defp apply_call_to_action(%Advert.Model{assignment: assignment} = advert) do
    active? = Assignment.Public.has_budget_capacity?(assignment)

    %{
      label: cta_label(active?),
      active?: active?,
      target: %{type: :event, value: "apply"},
      advert: advert,
      handle: &handle_apply/1
    }
  end

  defp cta_label(true), do: dgettext("eyra-advert", "promotion.apply.button")
  defp cta_label(false), do: dgettext("eyra-advert", "promotion.full.button")

  # Existing pool members bypass the consent screen and go straight
  # to the assignment; non-members are routed through the pool join
  # gate with a `return_to` so they land on the same assignment after
  # accepting the join consent, instead of being silently added and
  # sent straight in.
  def handle_apply(
        %{
          assigns: %{
            current_user: user,
            vm: %{
              call_to_action: %{
                advert: %{assignment: %{id: id}, promotion: promotion, submission: %{pool: pool}}
              }
            }
          }
        } = socket
      ) do
    Promotion.Private.log_performance_event(promotion, :clicks)
    apply_path = ~p"/assignment/#{id}/apply"

    if Pool.Public.participant?(pool, user) do
      LiveView.push_navigate(socket, to: apply_path)
    else
      slug = Pool.Model.slug(pool)
      LiveView.push_navigate(socket, to: ~p"/pool/#{slug}/join?return_to=#{apply_path}")
    end
  end
end
