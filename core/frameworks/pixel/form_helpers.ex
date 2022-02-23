defmodule Frameworks.Pixel.FormHelpers do
  @moduledoc """
  Conveniences for accassing the form using Surface.
  """
  alias Frameworks.Pixel.ErrorHelpers

  def form(assigns) do
    context(assigns)
    |> Map.get({Surface.Components.Form, :form})
  end

  def field_has_error?(assigns, form) do
    ErrorHelpers.has_error?(form, assigns.field)
  end

  def field_is_valid?(assigns, form) do
    !(assigns |> field_has_error?(form))
  end

  def field_error_tag(assigns, form) do
    ErrorHelpers.error_tag(form, assigns.field)
  end

  def label_color(assigns, form, default \\ "text-grey1") do
    if assigns |> field_has_error?(form) do
      "text-warning"
    else
      default
    end
  end

  def focus_label_color(background) do
    case background do
      :light -> "text-primary"
      _ -> "text-tertiary"
    end
  end

  def border_color(assigns, form, default \\ "border-grey3") do
    if assigns |> field_has_error?(form) do
      "border-warning"
    else
      default
    end
  end

  def focus_border_color(background) do
    case background do
      :light -> "border-primary"
      _ -> "border-tertiary"
    end
  end

  def target(%{options: options} = _form), do: options[:phx_target]
  def target(_form), do: nil

  defp context(assigns) do
    assigns[:__context__]
  end
end
