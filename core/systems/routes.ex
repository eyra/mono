defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :next_action,
        :notification
      ]
    end
  end
end
