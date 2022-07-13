defmodule Frameworks.Pixel.Dropdown.OptionsView do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Dropdown

  prop(options, :list, required: true)
  prop(target, :any)

  def render(assigns) do
    ~F"""
    <div class="bg-white shadow-2xl rounded">
      <div class="max-h-dropdown overflow-y-scroll py-4">
        <div class="flex flex-col items-left">
          {#for {option, index} <- Enum.with_index(@options)}
            <div class="flex-shrink-0">
              <Dropdown.OptionView index={index} {...option} target={@target} />
            </div>
          {/for}
        </div>
      </div>
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Dropdown.Options.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Dropdown.OptionsView,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Dropdown options view",
    height: "1280px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <OptionsView options={[
      %{id: 1, label: "Dropdown item 1"},
      %{id: 2, label: "Dropdown item 2"},
      %{id: 3, label: "Dropdown item 3"},
      %{id: 4, label: "Dropdown item 4"},
      %{id: 5, label: "Dropdown item 5"},
      %{id: 6, label: "Dropdown item 6"},
      %{id: 7, label: "Dropdown item 7"},
      %{id: 8, label: "Dropdown item 8"},
      %{id: 9, label: "Dropdown item 9"},
      %{id: 10, label: "Dropdown item 10"},
      %{id: 11, label: "Dropdown item 11"},
      %{id: 12, label: "Dropdown item 12"},
      %{id: 13, label: "Dropdown item 13"}
    ]} />
    """
  end
end
