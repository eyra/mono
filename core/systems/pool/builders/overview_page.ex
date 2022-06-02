defmodule Systems.Pool.Builders.OverviewPage do
  import CoreWeb.Gettext
  import Frameworks.Utility.Guards

  import CoreWeb.UI.Responsive.Breakpoint

  alias Core.Accounts
  alias Core.ImageHelpers
  alias Core.Pools

  alias Systems.{
    Pool,
    Assignment,
    Campaign,
    Bookkeeping
  }

  def view_model(_pool, assigns, url_resolver) do
    %{
      tabs: create_tabs(assigns, url_resolver)
    }
  end

  defp create_tabs(%{initial_tab: initial_tab} = assigns, url_resolver) do
    students = load_students()
    campaigns = load_campaigns(url_resolver)
    years = load_years(assigns)

    [
      %{
        id: :students,
        title: dgettext("link-studentpool", "tabbar.item.students"),
        component: Pool.StudentsView,
        props: %{students: students},
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
        props: %{years: years},
        type: :fullpage,
        active: initial_tab === :dashboard
      }
    ]
  end

  defp load_students() do
    Accounts.list_students([:profile, :features])
  end

  defp load_campaigns(url_resolver) do
    preload = Campaign.Model.preload_graph(:full)

    Campaign.Context.list_submitted(preload: preload)
    |> Enum.map(&convert_to_vm(url_resolver, &1))
  end

  defp load_years(%{breakpoint: breakpoint} = _assigns) do
    first_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year1_2021"])
      |> Enum.map(& &1.balance_credit)

    second_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year2_2021"])
      |> Enum.map(& &1.balance_credit)

    [
      create_year(:first, first_year_rewards, scale(:first, breakpoint)),
      create_year(:second, second_year_rewards, scale(:second, breakpoint))
    ]
  end

  defp scale(:first, {:unknown, _}), do: 5
  defp scale(:first, breakpoint), do: value(breakpoint, 10, md: %{0 => 5})
  defp scale(:second, _), do: 1

  defp create_year(year, credits, scale) do
    study_program_codes = Core.Enums.StudyProgramCodes.values_by_year(year)
    year_string = Core.Enums.StudyProgramCodes.year_to_string(year)

    target = Pools.target(year)

    active_credits = credits |> Enum.filter(&(&1 > 0 and &1 < target))
    passed_credits = credits |> Enum.filter(&(&1 >= target))

    truncated_credits =
      credits
      |> Enum.map(
        &if &1 < target do
          &1
        else
          target
        end
      )

    total_student_count = Pools.count_students(study_program_codes)
    active_student_count = active_credits |> Enum.count()
    passed_student_count = passed_credits |> Enum.count()
    inactive_student_count = total_student_count - (active_student_count + passed_student_count)

    total_credits = Statistics.sum(truncated_credits) |> do_round()
    pending_credits = Campaign.Context.pending_rewards(year)
    target_credits = total_student_count * target

    %{
      title: dgettext("link-studentpool", "year.label", year: year_string),
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
          number: inactive_student_count,
          color:
            if inactive_student_count == 0 do
              :positive
            else
              :negative
            end
        },
        %{
          label: dgettext("link-studentpool", "active.students"),
          number: active_student_count,
          color:
            if active_student_count == 0 do
              :negative
            else
              :primary
            end
        },
        %{
          label: dgettext("link-studentpool", "passed.students"),
          number: passed_student_count,
          color:
            if passed_student_count == 0 do
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
           promotion: %{
             title: title,
             image_id: image_id,
             submission:
               %{
                 id: submission_id,
                 updated_at: updated_at
               } = submission
           },
           promotable_assignment:
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
        :drafted -> :tertiary
        :submitted -> :delete
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

  defp campaign_status(%{status: status} = submission) do
    case status do
      :accepted -> Pool.Context.published_status(submission)
      :idle -> :drafted
      :submitted -> :submitted
      :completed -> :completed
    end
  end
end
