defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :project,
        :campaign,
        :org,
        :admin,
        :support,
        :assignment,
        :next_action,
        :notification,
        :promotion,
        :pool,
        :lab,
        :benchmark,
        :feldspar,
        :document,
        :alliance,
        :budget
      ]
    end
  end
end
