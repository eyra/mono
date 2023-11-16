defprotocol Frameworks.Concept.ContentModel do
  @spec ready?(t) :: boolean()
  def ready?(_t)

  @spec form(t) :: atom()
  def form(_t)
end

defimpl Frameworks.Concept.ContentModel, for: Ecto.Changeset do
  def form(%{data: data}), do: Frameworks.Concept.ContentModel.form(data)
  def ready?(changeset), do: changeset.valid?()
end
