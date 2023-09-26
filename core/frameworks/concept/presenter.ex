defmodule Frameworks.Concept.Presenter do
  @type model :: pos_integer() | map
  @type page :: atom()
  @type assigns :: map

  @callback view_model(model, page, assigns) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Concept.Presenter

      alias Frameworks.Utility.ViewModelBuilder, as: Builder
    end
  end
end
