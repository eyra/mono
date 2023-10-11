defprotocol Frameworks.Concept.Directable do
  @spec director(t) :: atom()
  def director(_t)
end
