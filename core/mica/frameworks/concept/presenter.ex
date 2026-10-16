defmodule Frameworks.Concept.Presenter do
  @type page :: atom()
  @type model :: pos_integer() | map | nil
  @type assigns :: map

  @callback view_model(page, model, assigns) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Concept.Presenter

      alias Frameworks.Utility.ViewModelBuilder, as: Builder

      # Convention: ViewBuilder = View module name + "Builder"
      # e.g., Systems.Assignment.LandingPage → Systems.Assignment.LandingPageBuilder
      defp builder(module) do
        parts = Module.split(module)
        namespace = parts |> Enum.drop(-1) |> Module.concat()
        view_name = List.last(parts)
        Module.concat(namespace, view_name <> "Builder")
      end
    end
  end
end
