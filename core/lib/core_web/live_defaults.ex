defmodule CoreWeb.LiveDefaults do
  def update_defaults(%{assigns: assigns} = socket, props, defaults) do
    assigns =
      Enum.reduce(defaults, assigns, fn {key, default}, acc ->
        value = Map.get(props, key, default)
        Map.put(acc, key, value)
      end)

    Map.put(socket, :assigns, assigns)
  end

  defmacro __using__(_opts \\ nil) do
    quote do
      import CoreWeb.LiveDefaults
    end
  end
end
