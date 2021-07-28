defmodule EyraUI.ViewModel do
  def sub_props(props) when is_list(props), do: props
  def sub_props(_), do: nil

  def concat(nil, first), do: [first]
  def concat(path, next), do: path ++ [next]

  defmacro prop_functions(path, value) when is_list(value) do
    path_string = Enum.join(path, "_")

    quote do
      def unquote(:"#{path_string}")(view_model) do
        Kernel.get_in(view_model, unquote(path))
      end

      def unquote(:"has_#{path_string}?")(view_model) do
        Kernel.get_in(view_model, unquote(path)) != nil
      end
    end
  end

  defmacro prop_functions(path, value) do
    path_string = Enum.join(path, "_")

    quote do
      def unquote(:"#{path_string}")(view_model, default \\ unquote(value)) do
        case Kernel.get_in(view_model, unquote(path)) do
          nil -> default
          value -> value
        end
      end

      def unquote(:"has_#{path_string}?")(view_model) do
        Kernel.get_in(view_model, unquote(path)) != nil
      end
    end
  end

  defmacro parse(props, path \\ nil)

  defmacro parse(props, path) when is_list(props) do
    for {name, value} <- props do
      next_path = EyraUI.ViewModel.concat(path, name)
      next_props = EyraUI.ViewModel.sub_props(value)

      quote do
        EyraUI.ViewModel.prop_functions(unquote(next_path), unquote(value))
        EyraUI.ViewModel.parse(unquote(next_props), unquote(next_path))
      end
    end
  end

  defmacro parse(_, _) do
  end

  defmacro __using__(props) do
    quote do
      require EyraUI.ViewModel
      EyraUI.ViewModel.parse(unquote(props))
    end
  end
end
