defmodule Mix.Tasks.Content.Generate do
  @moduledoc """
  The `content.generate` task can be used to fill the database with test
  content. All content is randomly generated. A fixed ratio between items
  (for instance members to researchers) is used. The ratios are similar to
  the (expected) production ratios between different entities.

  The amount of content can be directed by providing a `multiplier`
  argument. This should be an integer and multiplies the number of items
  generated.

  This task can be run multiple times. It will insert additional content
  each time it runs.
  """
  use Mix.Task
  alias Core.Factories

  @progress_bar_format [
    right: [],
    bar: "█",
    blank: "░"
  ]

  def sample(enumarable, opts \\ []) do
    minimum = Keyword.get(opts, :min, 0)
    maximum = Keyword.get(opts, :max, Enum.count(enumarable))
    sample_size = Enum.random(minimum..maximum)
    Enum.take_random(enumarable, sample_size)
  end

  def random_groups(enumarable, group_count) do
    enumarable
    |> Enum.map(&{:rand.uniform(group_count), &1})
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.values()
  end

  defp progress_bar(label, item, item_count) do
    ProgressBar.render(
      item,
      item_count,
      Keyword.put(@progress_bar_format, :left, [String.pad_trailing(label, 12)])
    )
  end

  @shortdoc "Generate (random) content for the application"
  def run(args) do
    Mix.Task.run("app.start")
    Logger.configure(level: :warning)

    case (args |> List.first() || "1") |> Integer.parse() do
      :error ->
        IO.puts("The multiplier must be an integer")
        exit({:shutdown, 1})

      {multiplier, _} ->
        study_count = 4 * multiplier
        member_count = 40 * multiplier
        researcher_count = 1 * multiplier
        max_participant_count = min(200, member_count)
        max_researchers_per_study = 3

        researchers =
          for i <- 1..researcher_count do
            progress_bar("Researchers", i, researcher_count)
            Factories.insert!(:researcher)
          end

        members =
          for i <- 1..member_count do
            progress_bar("Members", i, member_count)

            Factories.insert!(:member)
          end

        for i <- 1..study_count do
          progress_bar("Studies", i, study_count)

          members |> sample(max: max_participant_count)

          [applied_participants, entered_participants, rejected_participants] =
            random_groups(members, 3)

          owning_researcher_roles =
            sample(researchers, min: 1, max: max_researchers_per_study)
            |> map_role_assignment(:owner)

          Factories.insert!(:study,
            role_assignments: owning_researcher_roles,
            participants:
              map_participant(applied_participants, :applied) ++
                map_participant(entered_participants, :entered) ++
                map_participant(rejected_participants, :rejected)
          )
        end
    end
  end

  def map_role_assignment(enumerable, role) do
    Factories.map_build(
      enumerable,
      :role_assignment,
      &%{
        principal_id: &1.id,
        role: role
      }
    )
  end

  def map_participant(enumerable, status) do
    Factories.map_build(
      enumerable,
      :participant,
      &%{
        user: &1,
        status: status
      }
    )
  end
end
