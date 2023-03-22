defmodule Frameworks.Pixel.FormHelpers do
  @moduledoc """
  Conveniences for accassing the form using Surface.
  """
  alias Frameworks.Pixel.ErrorHelpers
  alias Phoenix.LiveView.JS

  def field_has_error?(assigns, form) do
    ErrorHelpers.has_error?(form, assigns.field)
  end

  def field_is_valid?(assigns, form) do
    !(assigns |> field_has_error?(form))
  end

  def field_error_message(assigns, form) do
    ErrorHelpers.error_message(form, assigns.field)
  end

  def reset_field_color(js \\ %JS{}, field) do
    border_classes =
      [
        "border-grey3",
        "border-primary",
        "border-tertiary",
        "border-warning"
      ]
      |> Enum.join(" ")

    text_classes =
      [
        "text-grey1",
        "text-primary",
        "text-tertiary",
        "text-warning"
      ]
      |> Enum.join(" ")

    js
    |> JS.remove_class(border_classes, to: "##{field}", time: 0)
    |> JS.remove_class(text_classes, to: "##{field}_label", time: 0)
  end

  def set_field_color(js \\ %JS{}, field, options) do
    js
    |> reset_field_color(field)
    |> JS.add_class(get_border_color(options), to: "##{field}", time: 0)
    |> JS.add_class(get_text_color(options), to: "##{field}_label", time: 0)
  end

  def get_border_color(options), do: "border-#{get_field_color(options, "grey3")}"
  def get_text_color(options), do: "text-#{get_field_color(options, "grey1")}"

  def get_field_color({true, _, :light}, _), do: "primary"
  def get_field_color({true, _, _}, _), do: "tertiary"
  def get_field_color({false, error, _}, _) when is_binary(error) and error != "", do: "warning"
  def get_field_color({false, true, _}, _), do: "warning"
  def get_field_color({_, _, _}, default), do: default

  def target(%{options: options} = _form), do: options[:phx_target]
  def target(_form), do: nil
end
