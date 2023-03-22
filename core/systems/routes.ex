defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :org,
        :home,
        :admin,
        :support,
        :assignment,
        :campaign,
        :next_action,
        :notification,
        :promotion,
        :pool,
        :lab,
        :data_donation,
        :budget
      ]
    end
  end
end
