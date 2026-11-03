defmodule Frameworks.Pixel.Prism do
  @moduledoc """
  Prism's components as function components, built from Prism's design while
  Mica compiles (`button/1`, `tag/1`, …). See `Prism.Generator.Phoenix`.
  """
  use Prism.Generator.Phoenix, design: Prism.Design.Components
end
