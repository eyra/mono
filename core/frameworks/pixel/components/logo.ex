defmodule Frameworks.Pixel.Logo do
  use CoreWeb, :pixel

  @moduledoc """
  Logo component for product and platform logos.

  Directory structure:
  - /images/logos/products/  - Our product logos (Next, Eyra, PaNL, etc.)
  - /images/logos/platforms/ - External DDP platform logos (Facebook, Instagram, etc.)

  Product logo variants:
  - {name}.svg - Icon only (scalable)
  - {name}_wide.svg - With integrated text (hand-positioned)
  - {name}_standing.svg - Vertical variant (if exists)

  Platform logo variants:
  - {name}.svg - Circle variant (scalable, text-free)
  - {name}_square.svg - Square variant (scalable, text-free)
  """

  # Path functions for use outside of components

  def path(name, {:product, variant}), do: product_path(name, variant)
  def path(name, {:product}), do: product_path(name)
  def path(name, :product), do: product_path(name)
  def path(name, {:platform, variant}), do: platform_path(name, variant)
  def path(name, {:platform}), do: platform_path(name)
  def path(name, :platform), do: platform_path(name)

  defp product_path(name, variant \\ :default) do
    file = product_file(name, variant)
    "/images/logos/products/#{file}.svg"
  end

  defp platform_path(name, variant \\ :default) do
    file = platform_file(name, variant)
    "/images/logos/platforms/#{file}.svg"
  end

  defp product_file(name, :wide), do: "#{name}_wide"
  defp product_file(name, :standing), do: "#{name}_standing"
  defp product_file(name, _), do: "#{name}"

  defp platform_file(name, :square), do: "#{name}_square"
  defp platform_file(name, _), do: "#{name}"

  # Components

  attr(:name, :atom, required: true)
  attr(:variant, :atom, default: :default, values: [:default, :wide, :standing])
  attr(:class, :string, default: "")

  def product(assigns) do
    assigns = assign(assigns, :src, product_path(assigns.name, assigns.variant))

    ~H"""
    <img class={@class} src={@src} alt={"#{@name} logo"} />
    """
  end

  attr(:name, :atom, required: true)
  attr(:size, :atom, required: true, values: [:default, :wide])

  def menu_home(assigns) do
    ~H"""
    <div class="h-8 sm:h-12">
      <.product name={@name} variant={@size} class="object-scale-down h-full" />
    </div>
    """
  end

  attr(:platform, :atom, required: true)
  attr(:variant, :atom, default: :default, values: [:default, :square])
  attr(:class, :string, default: "")

  def platform(assigns) do
    assigns = assign(assigns, :src, platform_path(assigns.platform, assigns.variant))

    ~H"""
    <img class={@class} src={@src} alt={"#{@platform}"} />
    """
  end
end
