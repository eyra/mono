defprotocol Frameworks.Concept.Branch do
  # FIXME: add possibility to resolve dependencies to leafs (siblings)

  @type scope :: :self | :parent

  @spec name(t, scope) :: binary
  def name(_t, _scope)

  @spec hierarchy(t) :: list
  def hierarchy(_t)
end
