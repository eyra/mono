defprotocol Frameworks.GreenLight.AuthorizationNode do
  @spec id(t) :: integer() | nil
  def id(entity)
end

defimpl Frameworks.GreenLight.AuthorizationNode, for: Integer do
  def id(entity), do: entity
end

defimpl Frameworks.GreenLight.AuthorizationNode, for: Atom do
  def id(entity) when is_nil(entity), do: nil
end
