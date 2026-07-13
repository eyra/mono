defmodule Frameworks.Pixel.Logo do
  use CoreWeb, :pixel

  @moduledoc """
  Logo component for product, platform, and pool logos.

  Directory structure:
  - /images/logos/products/  - Eyra's own product family (Next, Eyra, Self, Yoda, ...)
  - /images/logos/platforms/ - External third-party brands (Google, Apple, TikTok, SurfConext, ...)
  - /images/logos/pools/     - Participant pool brand marks (Panl, LISS Panel, ...) —
                               neither Eyra products nor external third parties.
                               Each pool ships two assets: `<slug>.svg` (icon-only
                               avatar) and `<slug>_wide.svg` (wordmark for wider
                               contexts).

  Product logo variants:
  - {name}.svg - Icon only (scalable)
  - {name}_wide.svg - With integrated text (hand-positioned)
  - {name}_standing.svg - Vertical variant (if exists)

  Platform logo variants:
  - {name}.svg - Circle variant (scalable, text-free)
  - {name}_square.svg - Square variant (scalable, text-free)

  Pool logo variants:
  - {name}.svg - Icon-only avatar (default)
  - {name}_wide.svg - Wordmark (with integrated text)
  """

  # Path functions for use outside of components

  def path(name, {:product, variant}), do: build_path(:products, name, variant)
  def path(name, {:product}), do: build_path(:products, name, :default)
  def path(name, :product), do: build_path(:products, name, :default)
  def path(name, {:platform, variant}), do: build_path(:platforms, name, variant)
  def path(name, {:platform}), do: build_path(:platforms, name, :default)
  def path(name, :platform), do: build_path(:platforms, name, :default)
  def path(name, {:pool, variant}), do: build_path(:pools, name, variant)
  def path(name, {:pool}), do: build_path(:pools, name, :default)
  def path(name, :pool), do: build_path(:pools, name, :default)

  defp build_path(type, name, variant) do
    name
    |> to_string()
    |> String.downcase()
    |> file_with_variant(variant)
    |> then(&"/images/logos/#{type}/#{&1}.svg")
  end

  defp file_with_variant(name, :wide), do: "#{name}_wide"
  defp file_with_variant(name, :standing), do: "#{name}_standing"
  defp file_with_variant(name, :square), do: "#{name}_square"
  defp file_with_variant(name, _), do: name

  # Components

  attr(:name, :atom, required: true)
  attr(:variant, :atom, default: :default, values: [:default, :wide, :standing])
  attr(:class, :string, default: "")

  def product(assigns) do
    assigns = assign(assigns, :src, build_path(:products, assigns.name, assigns.variant))

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
    assigns = assign(assigns, :src, build_path(:platforms, assigns.platform, assigns.variant))

    ~H"""
    <img class={@class} src={@src} alt={"#{@platform}"} />
    """
  end

  attr(:name, :atom, required: true)
  attr(:variant, :atom, default: :default, values: [:default, :wide])
  attr(:class, :string, default: "")

  def pool(assigns) do
    assigns = assign(assigns, :src, build_path(:pools, assigns.name, assigns.variant))

    ~H"""
    <img class={@class} src={@src} alt={"#{@name} logo"} />
    """
  end
end
