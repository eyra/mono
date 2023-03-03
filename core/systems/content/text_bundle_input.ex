defmodule Systems.Content.TextBundleInput do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.{Inputs, TextInput}

  prop(form, :any)
  prop(target, :any)

  def render(assigns) do
    ~F"""
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
    """
  end
end
