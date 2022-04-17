defprotocol Frameworks.Utility.ViewModelBuilder do
  @type accumulator :: map
  @type model :: map | list
  @type page :: atom() | tuple()
  @type user :: map
  @type url_resolver :: (atom, list -> binary)

  @spec view_model(model, page, user, url_resolver) :: map
  def view_model(model, page, user, url_resolver)
end
