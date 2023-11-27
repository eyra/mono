defmodule Frameworks.Concept.Presenter do
  @type page :: atom()
  @type model :: pos_integer() | map | nil
  @type assigns :: map

  @callback view_model(page, model, assigns) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Concept.Presenter

      alias Frameworks.Utility.ViewModelBuilder, as: Builder
    end
  end
end
