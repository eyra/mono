defprotocol Frameworks.Utility.ViewModelBuilder do
  @type accumulator :: map
  @type model :: map | list
  @type page :: atom() | tuple()
  @type assigns :: map

  @spec view_model(model, page, assigns) :: map
  def view_model(model, page, assigns)
end
