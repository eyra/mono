defmodule Core.Enums.Base do
  @callback values() :: list(atom())

  defmacro __using__({name, values}) do
    quote do
      alias EyraUI.Selectors.Label
      import CoreWeb.Gettext

      def values do
        unquote(values)
      end

      def translate(value) do
        Gettext.dgettext(CoreWeb.Gettext, "eyra-enums", "#{unquote(name)}.#{value}")
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

      defmacro schema_values(_opts \\ []) do
        quote do
          unquote(values())
        end
      end

      defp translations do
        unquote do
          for value <- values do
            key = "#{name}.#{value}"

            quote do
              dgettext("eyra-enums", unquote(key))
            end
          end
        end
      end
    end
  end
end
