defmodule Systems.Userflow.Queries do
  import Ecto.Query

  alias Systems.Userflow

  def get_by_id(id) do
    from(u in Userflow.Model,
      where: u.id == ^id,
      preload: ^Userflow.Model.preload_graph(:down)
    )
  end

  def get_progress(step_id, user_id) do
    from(p in Userflow.ProgressModel,
      where: p.user_id == ^user_id and p.step_id == ^step_id,
      preload: ^Userflow.ProgressModel.preload_graph(:up)
    )
  end

  def get_steps_by_group(userflow_id, group) do
    from(s in Userflow.StepModel,
      where: s.userflow_id == ^userflow_id and s.group == ^group,
      order_by: s.order,
      preload: ^Userflow.StepModel.preload_graph(:down)
    )
  end

  def list_progress(userflow_id, user_id) do
    from(p in Userflow.ProgressModel,
      join: s in assoc(p, :step),
      where: p.user_id == ^user_id and s.userflow_id == ^userflow_id,
      preload: [step: ^Userflow.StepModel.preload_graph(:up)]
    )
  end
end
