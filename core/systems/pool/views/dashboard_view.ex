defmodule Systems.Pool.DashboardView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title2, Body}

  alias Systems.{
    Campaign
  }

  prop(user, :any, required: true)

  data(years, :map)

  def update(_params, socket) do
    pool = Core.Pools.get_by_name(:vu_students)
    first_year_criteria = %{study_program_codes: [:iba_1, :bk_1]}
    first_year_rewards = Campaign.Context.list_user_rewards(pool, first_year_criteria)
    first_year_inactive_students = Campaign.Context.list_inactive_users(first_year_criteria)

    second_year_criteria = %{study_program_codes: [:iba_2, :bk_2]}
    second_year_rewards = Campaign.Context.list_user_rewards(pool, second_year_criteria)
    second_year_inactive_students = Campaign.Context.list_inactive_users(second_year_criteria)

    years = [
      create_year(:first, first_year_inactive_students, first_year_rewards),
      create_year(:second, second_year_inactive_students, second_year_rewards)
    ]

    {
      :ok,
      socket |> assign(years: years)
    }
  end

  defp create_year(year, inactive_students, credits) do
    year_string = Core.Enums.StudyProgramCodes.year_to_string(year)

    %{
      title: dgettext("link-studentpool", "year.label", year: year_string),
      rows: [
        %{
          icon: "💤",
          title: dgettext("link-studentpool", "inactive.students"),
          value: Enum.count(inactive_students)
        },
        %{
          icon: "↓",
          title: dgettext("link-studentpool", "min.credits.earned.label"),
          value: Statistics.min(credits) |> do_round()
        },
        %{
          icon: "↑",
          title: dgettext("link-studentpool", "max.credits.earned.label"),
          value: Statistics.max(credits) |> do_round()
        },
        %{
          icon: "➗",
          title: dgettext("link-studentpool", "mean.credits.earned.label"),
          value: Statistics.mean(credits) |> do_round()
        },
        %{
          icon: "┅",
          title: dgettext("link-studentpool", "median.credits.earned.label"),
          value: Statistics.median(credits) |> do_round()
        },
        %{
          icon: "💯",
          title: dgettext("link-studentpool", "total.credits.earned.label"),
          value: Statistics.sum(credits) |> do_round()
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
          <table class="table-auto">
            <tr :for={row <- year.rows}>
              <td class="pr-4"><Body>{row.icon}</Body></td>
              <td class="pr-4"><Body>{row.title}</Body></td>
              <td><Body>{row.value}</Body></td>
            </tr>
          </table>
          <Spacing value="XL" />
        </div>
      </ContentArea>
    """
  end
end
