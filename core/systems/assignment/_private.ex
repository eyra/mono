defmodule Systems.Assignment.Private do
  require Logger

  alias Systems.{
    Workflow,
    Crew
  }

  def task_template(%{special: :data_donation}, %Workflow.ItemModel{id: item_id}) do
    ["item=#{item_id}"]
  end

  def task_identifier(
        %{special: :data_donation},
        %Workflow.ItemModel{id: item_id},
        %Crew.MemberModel{id: member_id}
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end

  # Depricated
  def task_identifier(tool, user) do
    Logger.warn(
      "`Systems.Assignment.Private.task_identifier/2` is deprecated; call `task_identifier/3` instead."
    )

    [
      Atom.to_string(Frameworks.Concept.ToolModel.key(tool)),
      Integer.to_string(tool.id),
      Integer.to_string(user.id)
    ]
  end
end
