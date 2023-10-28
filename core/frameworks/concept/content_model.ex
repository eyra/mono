defprotocol Frameworks.Concept.ContentModel do
  @spec ready?(t) :: boolean()
  def ready?(_t)

  @spec form(t) :: atom()
  def form(_t)
end
