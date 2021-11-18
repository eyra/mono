defmodule Frameworks.Pixel.Dynamic do
  use Surface.Component

  prop(component, :module, required: true)
  prop(props, :map, default: %{})

  slot(default)

  def render(assigns) do
    props =
      assigns
      |> Map.get(:props)
      |> Map.merge(%{__surface__: %{groups: %{__default__: %{binding: false, size: 0}}}})

    ~H"""
    {{ live_component(@socket, @component, props) }}
    """
  end
end
