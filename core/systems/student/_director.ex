defmodule Systems.Student.Director do
  defmodule Error do
    @moduledoc false
    defexception [:message]
  end

  @behaviour Systems.Pool.External

  alias Systems.{
    Student,
    Pool,
    Budget
  }

  @impl true
  def overview_plugin(user) do
    %{
      module: Student.Pool.OverviewPlugin,
      props: %{id: :student_pools, user: user}
    }
  end

  @impl true
  def submission_plugin(_user), do: nil

  @impl true
  def inclusion_criteria() do
    [:genders, :dominant_hands, :native_languages]
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
end
