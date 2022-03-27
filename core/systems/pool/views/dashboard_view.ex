defmodule Systems.Pool.DashboardView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Widget.{Metric, ValueDistribution}

  alias Systems.{
    Bookkeeping
  }

  prop(user, :any, required: true)

  data(years, :map)

  def update(_params, socket) do
    first_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year1_2021"])
      |> Enum.map(& &1.balance_credit)

    # first_year_inactive_students = Campaign.Context.list_inactive_users(first_year_criteria)

    second_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year2_2021"])
      |> Enum.map(& &1.balance_credit)

    # second_year_inactive_students = Campaign.Context.list_inactive_users(second_year_criteria)

    years = [
      create_year(:first, first_year_rewards),
      create_year(:second, second_year_rewards)
    ]

    {
      :ok,
      socket |> assign(years: years)
    }
  end

  defp create_year(year, credits) do
    study_program_codes = Core.Enums.StudyProgramCodes.values_by_year(year)
    year_string = Core.Enums.StudyProgramCodes.year_to_string(year)

    total_student_count = Core.Pools.count_students(study_program_codes)
    active_student_count = credits |> Enum.filter(&(&1 > 0)) |> Enum.count()
    inactive_student_count = total_student_count - active_student_count

    min_credits = Enum.min(credits, fn -> 0 end)
    max_credits = Enum.max(credits, fn -> 0 end)
    total_credits = Statistics.sum(credits) |> do_round()

    %{
      title: dgettext("link-studentpool", "year.label", year: year_string),
      credits: credits,
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
          label: dgettext("link-studentpool", "min.credits.earned.label"),
          number: min_credits,
          color:
            if min_credits < 60 do
              :negative
            else
              :positive
            end
        },
        %{
          label: dgettext("link-studentpool", "max.credits.earned.label"),
          number: max_credits,
          color:
            if max_credits < 60 do
              :warning
            else
              :positive
            end
        },
        %{
          label: dgettext("link-studentpool", "total.credits.earned.label"),
          number: total_credits,
          color: :primary
        }
      ]
    }
  end

  defp do_round(number) when is_float(number),
    do: number |> Decimal.from_float() |> Decimal.round(2)

  defp do_round(number), do: number

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <div :for={year <- @years}>
          <Title2>{year.title}</Title2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-8 h-full">
            <div class="col-span-2 row-span-2">
              <ValueDistribution scale={10} values={year.credits}/>
            </div>
            <div :for={metric <- year.metrics}>
              <Metric {...metric}/>
            </div>
          </div>
          <Spacing value="XXL" />
        </div>
      </ContentArea>
    """
  end
end
