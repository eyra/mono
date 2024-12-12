defmodule Core.Enums.Base do
  @callback values() :: list(atom())

  defmacro __using__({name, values}) do
    quote do
      use Gettext, backend: CoreWeb.Gettext

      def values(filter \\ nil)

      def values(nil) do
        unquote(values)
      end

      def values(filter) when is_list(filter) do
        filter = convert_to_atoms(filter)

        unquote(values)
        |> Enum.filter(&Enum.member?(filter, &1))
      end

      def contains(atom) when is_atom(atom) do
        contains(Atom.to_string(atom))
      end

      def contains(binary) when is_binary(binary) do
        values()
        |> Enum.map(&Atom.to_string/1)
        |> Enum.member?(binary)
      end

      def translate(value) do
        if contains(value) do
          Gettext.dgettext(CoreWeb.Gettext, "eyra-enums", "#{unquote(name)}.#{value}")
        else
          value
        end
      end

      def labels(active_values \\ [], filter \\ nil)

      def labels(nil, filter), do: labels([], filter)

      def labels(active_values, filter) when is_list(active_values) do
        active_values = convert_to_atoms(active_values)

        values(filter)
        |> Enum.map(&convert_to_label(&1, active_values))
      end

      def labels(active_value, filter) do
        labels([active_value], filter)
      end

      defp convert_to_atoms(values) when is_list(values) do
        Enum.map(values, &convert_to_atom(&1))
      end

      defp convert_to_atom(value) when is_binary(value), do: String.to_existing_atom(value)
      defp convert_to_atom(value) when is_atom(value), do: value

      defp convert_to_label(value, active_values) when is_atom(value) do
        value_as_string =
          value
          |> Atom.to_string()
          |> translate()

        active =
          active_values
          |> Enum.member?(value)

        %{id: value, value: value_as_string, active: active}
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
