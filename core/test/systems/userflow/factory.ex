defmodule Systems.Userflow.Factory do
  use ExMachina.Ecto, repo: Core.Repo

  alias Core.Repo
  alias Systems.Userflow

  def userflow_factory do
    %Userflow.Model{}
  end

  def step_factory do
    %Userflow.StepModel{
      order: sequence(:order, & &1),
      group: sequence(:group, &"group-#{&1}")
    }
  end

  def progress_factory do
    %Userflow.ProgressModel{}
  end

  @doc """
  Creates a complete userflow with multiple steps and groups.
  """
  def userflow(step_count \\ 3) do
    userflow = insert(:userflow)
    steps = insert_list(step_count, :step, %{userflow: userflow})
    %{userflow | steps: steps}
  end

  def userflow_started(user \\ Core.Factories.insert!(:member)) do
    userflow = %{steps: steps} = userflow()
    insert(:progress, %{user: user, step: Enum.at(steps, 0)})
    userflow |> Repo.preload(steps: [:progress])
  end

  def userflow_finished(user \\ Core.Factories.insert!(:member)) do
    userflow = %{steps: steps} = userflow()

    for step <- steps do
      insert(:progress, %{user: user, step: step})
    end

    userflow |> Repo.preload(steps: [:progress])
  end

  @doc """
  Creates a step with associated progress records for multiple users.
  """
  def step__progress(user \\ Core.Factories.insert!(:member)) do
    step = insert(:step)
    progress = insert(:progress, %{user: user, step: step})
    %{step | progress: [progress]}
  end
end
