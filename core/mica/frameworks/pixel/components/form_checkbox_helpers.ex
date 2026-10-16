defmodule Frameworks.Pixel.Form.CheckboxHelpers do
  defmacro __using__(_opts) do
    quote do
      def handle_event(
            "toggle",
            %{"checkbox" => checkbox},
            %{assigns: %{entity: entity}} = socket
          ) do
        field = String.to_atom(checkbox)

        new_value =
          case Map.get(entity, field) do
            nil -> true
            value -> not value
          end

        attrs = %{field => new_value}

        {
          :noreply,
          socket
          |> save(entity, :auto_save, attrs)
        }
      end
    end
  end
end
