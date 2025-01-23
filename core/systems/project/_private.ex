defmodule Systems.Project.Private do
  alias Systems.Project

  def get_project_key(%Project.Model{root: %Project.NodeModel{id: id}} = _project) do
    "project_node=#{id}"
  end
end
