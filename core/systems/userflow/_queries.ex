defmodule Systems.Userflow.Queries do
  import Ecto.Query

  alias Systems.Userflow.{
    Model,
    StepModel,
    ProgressModel
  }

  def get_by_identifier(identifier) do
    from(u in Model,
      where: u.identifier == ^identifier,
      preload: ^Model.preload_graph(:down)
    )
  end

  def get_progress(user_id, step_id) do
    from(p in ProgressModel,
      where: p.user_id == ^user_id and p.step_id == ^step_id,
      preload: ^ProgressModel.preload_graph(:up)
    )
  end

  def get_steps_by_group(userflow_id, group) do
    from(s in StepModel,
      where: s.userflow_id == ^userflow_id and s.group == ^group,
      order_by: s.order,
      preload: ^StepModel.preload_graph(:down)
    )
  end

  def get_user_progress(user_id, userflow_id) do
    from(p in ProgressModel,
      join: s in assoc(p, :step),
      where: p.user_id == ^user_id and s.userflow_id == ^userflow_id,
      preload: [step: ^StepModel.preload_graph(:up)]
    )
  end
end
