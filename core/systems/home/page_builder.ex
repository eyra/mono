defmodule Systems.Home.PageBuilder do
  use CoreWeb, :verified_routes
  use Core.FeatureFlags

  use Gettext, backend: CoreWeb.Gettext
  import Frameworks.Utility.List

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Utility.ViewModelBuilder
  alias Systems.Home

  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Advert
  alias Systems.NextAction
  alias Systems.Pool
  alias Systems.Crew

  # For guest users
  def view_model(_, %{current_user: nil}) do
    %{
      hero: %{
        type: :landing_page,
        params: %{
          title: dgettext("eyra-home", "member.title"),
          caption: dgettext("eyra-home", "member.caption")
        }
      },
      active_menu_item: :home,
      next_best_action: nil,
      view_type: :guest,
      include_right_sidepadding?: false
    }
  end

  # For logged in users
  def view_model(_, %{current_user: user} = assigns) do
    panl? = panl_participant?(user)
    put_locale(user, panl?)

    %{
      hero: %{
        type: :landing_page,
        params: %{
          title: dgettext("eyra-home", "member.title"),
          caption: dgettext("eyra-home", "member.caption")
        }
      },
      active_menu_item: :home,
      next_best_action: NextAction.Public.next_best_action(user),
      view_type: :logged_in,
      blocks: blocks(user, assigns, panl?: panl?),
      include_right_sidepadding?: false
    }
  end

  defp panl_participant?(%Account.User{} = user) do
    if pool = Pool.Public.get_panl() do
      Pool.Public.participant?(pool, user)
    else
      false
    end
  end

  defp put_locale(%Systems.Account.User{creator: false}, true) do
    CoreWeb.Live.Hook.Locale.put_locale("nl")
  end

  defp put_locale(_, _) do
    CoreWeb.Live.Hook.Locale.put_locale("en")
  end

  defp block_keys(%Account.User{}, opts) do
    [:next_best_action, :available_adverts]
    |> append_if(:participated, feature_enabled?(:panl) and Keyword.get(opts, :panl?, false))
  end

  defp blocks(model, assigns, opts) do
    block_keys(model, opts)
    |> Enum.map(&{&1, block(&1, model, assigns, opts)})
    |> Enum.reject(fn {_, map} -> map == nil end)
  end

  defp block(:next_best_action, %Account.User{} = user, _assigns, _opts) do
    if next_best_action = NextAction.Public.next_best_action(user) do
      %{
        module: Home.NextBestActionView,
        params: %{
          next_best_action: next_best_action
        }
      }
    else
      nil
    end
  end

  defp block(:participated, %Account.User{} = user, _assigns, _opts) do
    content_items =
      Assignment.Public.list_by_participant(user, Assignment.Model.preload_graph(:down))
      |> Enum.map(&to_content_item(&1, user))

    if Enum.empty?(content_items) do
      nil
    else
      %{
        module: Home.ParticipatedView,
        params: %{
          content_items: content_items
        }
      }
    end
  end

  defp block(:available_adverts, %Account.User{} = user, assigns, _opts) do
    cards =
      Advert.Public.list_by_status(:online, preload: Advert.Model.preload_graph(:down))
      |> Enum.filter(&(Advert.Public.validate_open(&1, user) == :ok))
      |> Enum.map(&to_card(&1, assigns))

    %{
      module: Home.AdvertsView,
      params: %{
        title: dgettext("eyra-home", "available.member.title"),
        cards: cards
      }
    }
  end

  defp block(:available_adverts, _, assigns, _opts) do
    cards =
      Advert.Public.list_by_status(:online, preload: Advert.Model.preload_graph(:down))
      |> Enum.filter(&Advert.Public.validate_open(&1))
      |> Enum.map(&to_card(&1, assigns))

    %{
      module: Home.AdvertsView,
      params: %{
        title: dgettext("eyra-home", "available.visitor.title"),
        cards: cards
      }
    }
  end

  defp block(_, _, _assigns, _opts), do: nil

  defp to_content_item(
         %Assignment.Model{
           id: assignment_id,
           crew: crew,
           info: %{title: title, subtitle: subtitle}
         },
         user
       ) do
    tasks = Crew.Public.list_tasks_for_user(crew, user)
    finished? = Crew.Public.tasks_finished?(Enum.map(tasks, & &1.id))

    quick_summary =
      if finished? do
        finished_at = most_recent_completed_at(tasks)
        get_quick_summary(finished_at)
      else
        case Crew.Public.get_member(crew, user) do
          %{inserted_at: timestamp} -> get_quick_summary(timestamp)
          _ -> ""
        end
      end

    %{
      path: ~p"/assignment/#{assignment_id}",
      title: title,
      subtitle: subtitle,
      tag: tag(finished?),
      level: :critical,
      image: nil,
      quick_summary: quick_summary
    }
  end

  defp most_recent_completed_at(tasks) do
    Enum.reduce(tasks, nil, fn %{completed_at: completed_at}, acc ->
      Timestamp.max(completed_at, acc)
    end)
  end

  defp get_quick_summary(nil), do: ""

  defp get_quick_summary(timestamp) do
    timestamp
    |> CoreWeb.UI.Timestamp.apply_timezone()
    |> CoreWeb.UI.Timestamp.humanize()
  end

  defp tag(true) do
    %{text: dgettext("eyra-crew", "progress.finished.label"), type: :success}
  end

  defp tag(false) do
    %{text: dgettext("eyra-crew", "progress.started.label"), type: :warning}
  end

  defp to_card(%Advert.Model{} = advert, assigns) do
    ViewModelBuilder.view_model(advert, {:marketplace, :card}, assigns)
  end
end
