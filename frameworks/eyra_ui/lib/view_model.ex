defmodule EyraUI.ViewModel do
  defp sub_props(props) when is_list(props), do: props
  defp sub_props(_), do: nil

  defp concat(nil, first), do: [first]
  defp concat(path, next), do: path ++ [next]

  defmacro defgetter(p, value) do
    for path <- [p] do
      path_string = Enum.join(path, "_")

      quote do
        def unquote(:"#{path_string}")(view_model, default \\ unquote(value)) do
          case Kernel.get_in(view_model, unquote(path)) do
            nil -> default
            value -> value
          end
        end
      end
    end
  end

  defmacro defhas(path) do
    path_string = Enum.join(path, "_")

    path_string =
      if String.ends_with?(path_string, "?") do
        String.slice(path_string, 0, String.length(path_string) - 1)
      else
        path_string
      end

    quote do
      def unquote(:"has_#{path_string}?")(view_model) do
        case Kernel.get_in(view_model, unquote(path)) do
          nil -> false
          _ -> true
        end
      end
    end
  end

  defmacro defviewmodel(props) do
    quote do
      defviewmodel(unquote(props), nil)
    end
  end

  defmacro defviewmodel(nil, _), do: :noop
  defmacro defviewmodel([], _), do: :noop

  defmacro defviewmodel(props, path) do
    for {name, value} <- props do
      next_path = concat(path, name)
      next_props = sub_props(value)

      quote do
        defgetter(unquote(next_path), unquote(value))
        defhas(unquote(next_path))
        defviewmodel(unquote(next_props), unquote(next_path))
      end
    end
  end
end
