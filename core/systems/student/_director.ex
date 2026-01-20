defmodule Systems.Student.Director do
  defmodule Error do
    @moduledoc false
    defexception [:message]
  end

  @behaviour Frameworks.Concept.PoolDirector

  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Student,
    Pool,
    Budget
  }

  @impl true
  def overview_plugin(user) do
    %{
      module: Student.Pool.OverviewPlugin,
      params: %{id: :student_pools, user: user}
    }
  end

  @impl true
  def submission_plugin(_user), do: nil

  @impl true
  def inclusion_criteria() do
    [:genders]
  end

  @impl true
  def resolve_budget(pool_id, _user_id) do
    # Student pool rule: name of Pool, Budget & Currency are equal
    %{currency: currency} = Pool.Public.get!(pool_id, [:currency])

    case Budget.Public.get_by_currency!(currency, Budget.Model.preload_graph(:full)) do
      nil -> raise Error, message: "Student pool budget not available"
      budget -> budget
    end
  end

  @impl true
  def submit(submission_id) do
    submission = Pool.Public.get_submission!(submission_id)

    Pool.Public.update(submission, %{
      status: :submitted,
      submitted_at: Timestamp.naive_now()
    })
  end
end
