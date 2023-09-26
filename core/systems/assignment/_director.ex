defmodule Systems.Assignment.Director do
  @behaviour Frameworks.Concept.ToolDirector

  alias Frameworks.Concept.Directable
  alias Systems.Assignment

  @impl true
  def apply_member_and_activate_task(tool, user) do
    identifier = Assignment.Public.task_identifier(tool, user)
    assignment = Assignment.Public.get_by_tool(tool, Assignment.Model.preload_graph(:down))
    reward_value = Directable.director(assignment).reward_value(assignment)
    Assignment.Public.apply_member_and_activate_task(assignment, user, identifier, reward_value)
  end

  @impl true
  def search_subject(tool, user_ref) do
    Assignment.Public.search_subject(tool, user_ref)
  end

  @impl true
  def assign_tester_role(tool, user) do
    Assignment.Public.assign_tester_role(tool, user)
  end

  @impl true
  def authorization_context(tool, user) do
    Assignment.Public.get_task(tool, ["tool=#{tool.id}", "user=#{user.id}"])
  end
end
