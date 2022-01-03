defmodule Frameworks.Pixel.Button.PrimaryButton do
  @moduledoc """
  A colored button with white text.
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(to, :string, required: true)
  prop(label, :string, required: true)
  prop(bg_color, :string, default: "bg-primary")

  def render(assigns) do
    ~F"""
    <LiveRedirect to={@to} >
      <div class="flex">
        <div class={"flex-wrap pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px focus:outline-none rounded #{@bg_color}"}>
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button pl-4 pr-4">
              {@label}
            </div>
          </div>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end

defmodule Frameworks.Pixel.Button.PrimaryButton.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Button.PrimaryButton,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Primary Button",
    height: "420px",
    container: {:div, class: "buttons"}

  def render(assigns) do
    ~F"""
    <PrimaryButton to="/" label="Primary"/>
    <div class="mb-4"></div>
    <PrimaryButton to="/" label="Secondary" bg_color="bg-secondary"/>
    <div class="mb-4"></div>
    <PrimaryButton to="/" label="Tertiary" bg_color="bg-tertiary"/>
    <div class="mb-4"></div>
    <PrimaryButton to="/" label="Grey1" bg_color="bg-grey1"/>
    <div class="mb-4"></div>
    <PrimaryButton to="/" label="Delete" bg_color="bg-delete"/>
    <div class="mb-4"></div>
    <PrimaryButton to="/" label="Success" bg_color="bg-success"/>
    """
  end
end

defmodule Frameworks.Pixel.Button.Primary.Playground do
  use Surface.Catalogue.Playground,
    subject: Frameworks.Pixel.Button.PrimaryButton,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "110px",
    container: {:div, class: "buttons is-centered"}

  data(props, :map,
    default: %{
      to: "/",
      label: "My Button"
    }
  )

  def render(assigns) do
    ~F"""
    <PrimaryButton {...@props} />
    """
  end
end
