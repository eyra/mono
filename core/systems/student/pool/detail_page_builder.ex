defmodule Systems.Student.Pool.DetailPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  import CoreWeb.UI.Responsive.Breakpoint

  alias Systems.Pool
  alias Systems.Advert
  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Student

  def view_model(pool, assigns) do
    %{
      title: Pool.Model.title(pool),
      tabs: create_tabs(assigns, pool)
    }
  end

  defp create_tabs(%{initial_tab: initial_tab} = assigns, pool) do
    adverts = load_adverts(pool)
    participants = Pool.Public.list_participants(pool)
    dashboard = load_dashboard(assigns, pool)

    [
      %{
        id: :students,
        title: dgettext("link-studentpool", "tabbar.item.students"),
        live_component: Student.Overview,
        props: %{students: participants, pool: pool},
        type: :fullpage,
        active: initial_tab === :students
      },
      %{
        id: :adverts,
        title: dgettext("link-studentpool", "tabbar.item.adverts"),
        live_component: Advert.ListView,
        props: %{adverts: adverts},
        type: :fullpage,
        active: initial_tab === :adverts
      },
      %{
        id: :dashboard,
        title: dgettext("link-studentpool", "tabbar.item.dashboard"),
        live_component: Student.Pool.DashboardView,
        props: dashboard,
        type: :fullpage,
        active: initial_tab === :dashboard
      }
    ]
  end

  defp load_adverts(pool) do
    preload = Advert.Model.preload_graph(:down)

    Advert.Public.list_submitted(pool, preload: preload)
    |> Enum.map(&Pool.AdvertItemBuilder.view_model(&1))
  end

  defp scale({:unknown, _}), do: 5
  defp scale(breakpoint), do: value(breakpoint, 10, md: %{0 => 5})

  defp load_dashboard(
         %{breakpoint: breakpoint},
         %Pool.Model{
           target: target,
           currency: currency
         } = pool
       ) do
    participants = Pool.Public.list_participants(pool)
    scale = scale(breakpoint)

    wallets = Budget.Public.list_wallets(currency)

    credits = Enum.map(wallets, &Bookkeeping.AccountModel.balance(&1))

    active_credits = Enum.filter(credits, &(&1 > 0 and &1 < target))
    active_count = Enum.count(active_credits)

    passed_credits = Enum.filter(credits, &(&1 >= target))
    passed_count = Enum.count(passed_credits)

    total_count = participants |> Enum.count()

    inactive_count = total_count - (active_count + passed_count)

    truncated_credits =
      credits
      |> Enum.map(
        &if &1 < target do
          &1
        else
          target
        end
      )

    total_credits = Statistics.sum(truncated_credits) |> do_round()
    pending_credits = Budget.Public.pending_rewards(currency)
    target_credits = total_count * target

    %{
      credits: %{
        label: dgettext("link-studentpool", "credit.distribution.title"),
        values: active_credits,
        scale: scale
      },
      progress: %{
        label: dgettext("link-studentpool", "credit.progress.title"),
        target_amount: target_credits,
        done_amount: total_credits,
        pending_amount: pending_credits,
        done_label: dgettext("eyra-pool", "progress.done.label"),
        pending_label: dgettext("eyra-pool", "progress.pending.label"),
        target_label: dgettext("eyra-pool", "progress.target.label")
      },
      metrics: [
        %{
          label: dgettext("link-studentpool", "inactive.students"),
          metric: inactive_count,
          color:
            if inactive_count == 0 do
              :positive
            else
              :negative
            end
        },
        %{
          label: dgettext("link-studentpool", "active.students"),
          metric: active_count,
          color:
            if active_count == 0 do
              :negative
            else
              :primary
            end
        },
        %{
          label: dgettext("link-studentpool", "passed.students"),
          metric: passed_count,
          color:
            if passed_count == 0 do
              :negative
            else
              :positive
            end
        }
      ]
    }
  end

  defp do_round(number) when is_float(number),
    do: number |> Decimal.from_float() |> Decimal.round(2)

  defp do_round(number), do: number
end
