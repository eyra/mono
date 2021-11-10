defmodule Systems.Assignment.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Assignment
  }

  def dispatch(signal, %{director: :assignment} = object) do
    handle(signal, object)
  end

  def handle(:survey_tool_updated, tool), do: handle(:assignable_updated, tool)
  def handle(:lab_tool_updated, tool), do: handle(:assignable_updated, tool)
  def handle(:data_donation_tool_updated, tool), do: handle(:assignable_updated, tool)

  def handle(:assignable_updated, assignable) do
    assignment = Assignment.Context.get_by_assignable(assignable)
    Signal.Context.dispatch!(:assignment_updated, assignment)
  end

end
