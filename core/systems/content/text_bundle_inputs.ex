defmodule Systems.Content.TextBundleInputs do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.{Inputs, TextInput}

  prop(field, :atom)
  prop(target, :any)

  def render(assigns) do
    ~F"""
    <Inputs field={@field}>
      <Inputs field={:items} target={@target}>
        <div class="flex flex-row gap-4">
          <div class="flex-wrap w-12">
            <TextInput field={:locale} />
          </div>
          <div class="flex-grow">
            <TextInput field={:text} />
          </div>
        </div>
      </Inputs>
    </Inputs>
    """
  end
end
