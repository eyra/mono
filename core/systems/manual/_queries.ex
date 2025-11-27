defmodule Systems.Manual.Queries do
  import Ecto.Query

  alias Systems.Manual
  alias Systems.Assignment
  alias Systems.Workflow

  def get_by_id(id) do
    from(m in Manual.Model,
      where: m.id == ^id,
      preload: ^Manual.Model.preload_graph(:down)
    )
  end

  def get_by_id!(id) do
    from(m in Manual.Model,
      where: m.id == ^id,
      preload: ^Manual.Model.preload_graph(:down)
    )
    |> Core.Repo.one!()
  end

  def get_chapters(manual_id) do
    from(c in Manual.ChapterModel,
      where: c.manual_id == ^manual_id,
      preload: ^Manual.ChapterModel.preload_graph(:down)
    )
  end

  def get_chapter!(manual_id, chapter_id) do
    from(c in Manual.ChapterModel,
      where: c.manual_id == ^manual_id and c.id == ^chapter_id,
      preload: ^Manual.ChapterModel.preload_graph(:down)
    )
  end

  def get_chapter_by_userflow_step(userflow_step_id) do
    from(s in Manual.ChapterModel,
      where: s.userflow_step_id == ^userflow_step_id,
      preload: ^Manual.ChapterModel.preload_graph(:down)
    )
  end

  def get_page_by_userflow_step(userflow_step_id) do
    from(s in Manual.PageModel,
      where: s.userflow_step_id == ^userflow_step_id,
      preload: ^Manual.PageModel.preload_graph(:down)
    )
  end

  def get_pages_by_chapter(chapter_id) do
    from(s in Manual.PageModel,
      join: us in assoc(s, :userflow_step),
      where: us.userflow_id == ^chapter_id,
      order_by: us.order,
      preload: ^Manual.PageModel.preload_graph(:down)
    )
  end

  def previous_page(%Manual.PageModel{userflow_step: userflow_step}) do
    from(p in Manual.PageModel,
      where: p.userflow_step_id == ^userflow_step.id,
      where: p.order < ^userflow_step.order,
      order_by: [desc: p.order],
      limit: 1
    )
  end

  def assignment_for_manual(manual_id) do
    from(m in Manual.Model,
      join: mt in Manual.ToolModel,
      on: mt.manual_id == m.id,
      join: tr in Workflow.ToolRefModel,
      on: tr.manual_tool_id == mt.id,
      join: wi in Workflow.ItemModel,
      on: wi.tool_ref_id == tr.id,
      join: a in Assignment.Model,
      on: a.workflow_id == wi.workflow_id,
      where: m.id == ^manual_id,
      preload: ^[info: []],
      select: a
    )
  end
end
