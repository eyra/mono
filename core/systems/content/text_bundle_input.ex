defmodule Systems.Content.TextBundleInput do
  @moduledoc false
  use CoreWeb, :html
  import Frameworks.Pixel.Form

  attr(:form, :any)
  attr(:field, :atom)

  def text_bundle_input(assigns) do
    ~H"""
    <.inputs_for :let={subform} field={@form[@field]}>
      <.inputs_for :let={subsubform} field={subform[:items]}>
        <div class="flex flex-row gap-4">
          <div class="flex-wrap w-12">
            <.text_input form={subsubform} field={:locale} />
          </div>
          <div class="flex-grow">
            <.text_input form={subsubform} field={:text} />
          </div>
        </div>
      </.inputs_for>
    </.inputs_for>
    """
  end
end
