defmodule Systems.Userflow.Factories do
  @moduledoc """
  Test factories for the Userflow system.
  """
  alias Core.Factories
  alias Systems.Userflow.{Model, StepModel, ProgressModel}

  def build_userflow(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        identifier: "test_flow_#{System.unique_integer()}",
        title: "Test Flow"
      })

    %Model{}
    |> Model.changeset(attrs)
  end

  def create_userflow(attrs \\ %{}) do
    attrs
    |> build_userflow()
    |> Factories.insert!()
  end

  def build_step(userflow, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        identifier: "step_#{System.unique_integer()}",
        order: next_order(userflow),
        group: "default"
      })

    %StepModel{}
    |> StepModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:userflow, userflow)
  end

  def create_step(userflow, attrs \\ %{}) do
    attrs
    |> build_step(userflow)
    |> Factories.insert!()
  end

  def build_progress(user, step, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        visited_at: DateTime.utc_now()
      })

    %ProgressModel{}
    |> ProgressModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:step, step)
  end

  def create_progress(user, step, attrs \\ %{}) do
    attrs
    |> build_progress(user, step)
    |> Factories.insert!()
  end

  @doc """
  Creates a complete userflow with steps and optional progress.

  Options:
  - steps: number of steps to create (default: 3)
  - groups: list of group names to distribute steps across (default: ["intro"])
  - with_progress: user to create progress for (default: nil)
  - visited_steps: number of steps to mark as visited (default: 0)
  """
  def create_complete_userflow(attrs \\ %{}, opts \\ []) do
    steps = Keyword.get(opts, :steps, 3)
    groups = Keyword.get(opts, :groups, ["intro"])
    user = Keyword.get(opts, :with_progress)
    visited_steps = Keyword.get(opts, :visited_steps, 0)

    userflow = create_userflow(attrs)

    steps =
      1..steps
      |> Enum.map(fn i ->
        group = Enum.at(groups, rem(i - 1, length(groups)))
        create_step(userflow, %{order: i, group: group})
      end)

    if user && visited_steps > 0 do
      steps
      |> Enum.take(visited_steps)
      |> Enum.each(&create_progress(user, &1))
    end

    %{userflow | steps: steps}
  end

  # Private helpers

  defp next_order(userflow) do
    case userflow.steps do
      nil -> 1
      [] -> 1
      steps -> Enum.max_by(steps, & &1.order).order + 1
    end
  end
end
