defprotocol Frameworks.Utility.ViewModelBuilder do

  @type model :: map | list
  @type page :: atom()
  @type user :: map
  @type url_resolver :: ((atom, list) -> binary)

  @spec view_model(model, page, user, url_resolver) :: map
  def view_model(model, page, user, url_resolver)

end
