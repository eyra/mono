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
        :alliance,
        :lab,
        :benchmark,
        :feldspar,
        :document,
        :next_action,
        :notification,
        :promotion,
        :pool,
        :budget
      ]
    end
  end
end
