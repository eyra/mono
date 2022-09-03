defmodule Systems.Pool.Builders.DetailPage do
  import CoreWeb.Gettext
  import Frameworks.Utility.Guards

  import CoreWeb.UI.Responsive.Breakpoint

  alias Core.ImageHelpers

  alias Systems.{
    Pool,
    Assignment,
    Campaign,
    Budget,
    Bookkeeping
  }

  def view_model(pool, assigns, url_resolver) do
    %{
      title: Pool.Model.title(pool),
      tabs: create_tabs(assigns, url_resolver, pool)
    }
  end

  defp create_tabs(
         %{initial_tab: initial_tab} = assigns,
         url_resolver,
         %{participants: participants} = pool
       ) do
    campaigns = load_campaigns(url_resolver, pool)
    dashboard = load_dashboard(assigns, pool)

    [
      %{
        id: :students,
        title: dgettext("link-studentpool", "tabbar.item.students"),
        component: Pool.StudentsView,
        props: %{students: participants},
        type: :fullpage,
        active: initial_tab === :students
      },
      %{
        id: :campaigns,
        title: dgettext("link-studentpool", "tabbar.item.campaigns"),
        component: Pool.CampaignsView,
        props: %{campaigns: campaigns},
        type: :fullpage,
        active: initial_tab === :campaigns
      },
      %{
        id: :dashboard,
        title: dgettext("link-studentpool", "tabbar.item.dashboard"),
        component: Pool.DashboardView,
        props: dashboard,
        type: :fullpage,
        active: initial_tab === :dashboard
      }
    ]
  end

  defp load_campaigns(url_resolver, pool) do
    preload = Campaign.Model.preload_graph(:full)

    Campaign.Context.list_submitted(pool, preload: preload)
    |> Enum.map(&Campaign.Model.flatten(&1))
    |> Enum.map(&convert_to_vm(url_resolver, &1))
  end

  defp scale({:unknown, _}), do: 5
  defp scale(breakpoint), do: value(breakpoint, 10, md: %{0 => 5})

  defp load_dashboard(%{breakpoint: breakpoint}, %{
         target: target,
         currency: currency,
         participants: participants
       }) do
    scale = scale(breakpoint)

    wallets = Budget.Context.list_wallets(currency)

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
    pending_credits = Budget.Context.pending_rewards(currency)
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
        left_over_label: dgettext("eyra-pool", "progress.leftover.label")
      },
      metrics: [
        %{
          label: dgettext("link-studentpool", "inactive.students"),
          number: inactive_count,
          color:
            if inactive_count == 0 do
              :positive
            else
              :negative
            end
        },
        %{
          label: dgettext("link-studentpool", "active.students"),
          number: active_count,
          color:
            if active_count == 0 do
              :negative
            else
              :primary
            end
        },
        %{
          label: dgettext("link-studentpool", "passed.students"),
          number: passed_count,
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

  defp convert_to_vm(
         url_resolver,
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

    open_spot_count = Assignment.Context.open_spot_count(assignment)

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
      path: url_resolver.(Systems.Pool.SubmissionPage, id: submission_id),
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
      :accepted -> Pool.Context.published_status(submission)
      :idle -> :retracted
      :submitted -> :submitted
      :completed -> :completed
    end
  end
end
