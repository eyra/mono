defmodule Systems.Content.TextBundleInput do
  @moduledoc false
  use CoreWeb, :html
  import Frameworks.Pixel.Form

  attr(:form, :any)
  attr(:field, :atom)
  attr(:target, :any)

  def text_bundle_input(assigns) do
    ~H"""
    <.inputs form={@form} :let={%{form: subform}} field={@field}>
      <.inputs form={subform} :let={%{form: subsubform}} field={:items} target={@target}>
        <div class="flex flex-row gap-4">
          <div class="flex-wrap w-12">
            <.text_input form={subsubform} field={:locale} />
          </div>
          <div class="flex-grow">
            <.text_input form={subsubform} field={:text} />
          </div>
        </div>
      </.inputs>
    </.inputs>
    """
  end
end
