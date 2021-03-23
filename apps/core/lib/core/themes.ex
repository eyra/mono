defmodule Core.Themes do
  @moduledoc """
  Defines themes used to categorize studies or tools wihin studies.
  """

  alias EyraUI.Selectors.Label

  def values do
    [:health, :history, :politics, :art, :language, :technology, :society]
  end

  def labels(nil) do
    labels([])
  end

  def labels(active_values) when is_list(active_values) do
    values()
    |> Enum.map(&convert_to_label(&1, active_values))
  end

  defp convert_to_label(value, active_values) when is_atom(value) do
    value_as_string =
      value
      |> Atom.to_string()
      |> String.capitalize()

    active =
      active_values
      |> Enum.member?(value)

    %Label{id: value, value: value_as_string, active: active}
  end

  defmacro theme_values(_opts \\ []) do
    quote do
      unquote(Core.Themes.values())
    end
  end
end
