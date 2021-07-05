defmodule Core.Devices do
  @moduledoc """
  Defines device categories for participants.
  """

  alias EyraUI.Selectors.Label

  def values do
    [:phone, :tablet, :desktop]
  end

  def translate(value) do
    Gettext.dgettext(CoreWeb.Gettext, "eyra-study", "devices.#{value}")
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
      |> translate()

    active =
      active_values
      |> Enum.member?(value)

    %Label{id: value, value: value_as_string, active: active}
  end

  defmacro device_values(_opts \\ []) do
    quote do
      unquote(Core.Devices.values())
    end
  end

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote(
        for device <- values() do
          quote do
            dgettext("eyra-study", unquote("devices.#{device}"))
          end
        end
      )
    end
  end
end
