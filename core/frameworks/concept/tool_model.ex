defprotocol Frameworks.Concept.ToolModel do
  @spec key(t) :: atom()
  def key(_t)

  @spec auth_tree(t) :: tuple() | list() | struct() | nil
  def auth_tree(_t)

  @spec apply_label(t) :: binary()
  def apply_label(_t)

  @spec open_label(t) :: binary()
  def open_label(_t)

  @spec ready?(t) :: boolean()
  def ready?(_t)

  @spec form(t) :: atom()
  def form(_t)

  @spec launcher(t) :: %{url: binary()} | %{module: atom(), params: map()} | nil
  def launcher(_t)

  @spec task_labels(t) :: map()
  def task_labels(_t)

  @spec attention_list_enabled?(t) :: boolean()
  def attention_list_enabled?(_t)

  @spec group_enabled?(t) :: boolean()
  def group_enabled?(_t)
end

defimpl Frameworks.Concept.ToolModel, for: Ecto.Changeset do
  alias Frameworks.Concept.ToolModel
  def key(%{data: tool}), do: ToolModel.key(tool)
  def auth_tree(%{data: tool}), do: ToolModel.auth_tree(tool)
  def apply_label(%{data: tool}), do: ToolModel.apply_label(tool)
  def open_label(%{data: tool}), do: ToolModel.open_label(tool)
  def ready?(%{data: tool}), do: ToolModel.ready?(tool)
  def form(%{data: tool}), do: ToolModel.form(tool)
  def launcher(%{data: tool}), do: ToolModel.launcher(tool)
  def task_labels(%{data: tool}), do: ToolModel.task_labels(tool)
  def attention_list_enabled?(%{data: tool}), do: ToolModel.attention_list_enabled?(tool)
  def group_enabled?(%{data: tool}), do: ToolModel.group_enabled?(tool)
end
