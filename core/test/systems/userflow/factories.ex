defmodule Systems.Userflow.Factories do
  @moduledoc """
  Factory functions for creating Userflow system test data.
  """

  alias Core.Repo
  alias Systems.Userflow

  def build(:userflow, attrs) do
    %Userflow.Model{
      identifier: "test-#{System.unique_integer([:positive])}",
      title: "Test Userflow"
    }
    |> struct!(attrs)
  end

  def build(:step, attrs) do
    %Userflow.StepModel{
      identifier: "test-#{System.unique_integer([:positive])}",
      order: 1,
      group: "default"
    }
    |> struct!(attrs)
  end

  def build(:progress, attrs) do
    %Userflow.ProgressModel{
      visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
    |> struct!(attrs)
  end

  def insert!(factory_name), do: insert!(factory_name, %{})
  def insert!(factory_name, attrs), do: build(factory_name, attrs) |> Repo.insert!()

  @doc """
  Creates a complete userflow with multiple steps and groups.
  """
  def insert_complete_userflow!(attrs \\ %{}) do
    userflow = insert!(:userflow, attrs)

    steps =
      1..3
      |> Enum.map(fn order ->
        insert!(:step, %{
          userflow_id: userflow.id,
          order: order,
          group: "group-#{div(order - 1, 2) + 1}"
        })
      end)

    %{userflow | steps: steps}
  end

  @doc """
  Creates a step with associated progress records for multiple users.
  """
  def insert_step_with_progress!(user_ids, attrs \\ %{}) when is_list(user_ids) do
    step = insert!(:step, attrs)

    progress =
      user_ids
      |> Enum.map(fn user_id ->
        insert!(:progress, %{
          step_id: step.id,
          user_id: user_id
        })
      end)

    %{step | progress: progress}
  end

  @doc """
  Creates a userflow with all steps having progress for the given user.
  """
  def insert_userflow_with_progress!(user) do
    userflow = insert_complete_userflow!()

    steps =
      userflow.steps
      |> Enum.map(fn step ->
        progress =
          insert!(:progress, %{
            step_id: step.id,
            user_id: user.id
          })

        %{step | progress: [progress]}
      end)

    %{userflow | steps: steps}
  end
end
