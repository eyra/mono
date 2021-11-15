defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :home,
        :assignment,
        :campaign,
        :next_action,
        :notification,
        :promotion,
        :pool
      ]
    end
  end
end
