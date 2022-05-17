defmodule Systems.Presenter do
  @type model :: pos_integer() | map
  @type page :: atom()
  @type assigns :: map
  @type url_resolver :: (atom, list -> binary)

  @callback view_model(model, page, assigns, url_resolver) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Presenter

      alias Frameworks.Utility.ViewModelBuilder, as: Builder
    end
  end
end
