defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :home,
        :desktop,
        :project,
        :advert,
        :org,
        :admin,
        :support,
        :assignment,
        :next_action,
        :notification,
        :promotion,
        :pool,
        :lab,
        :graphite,
        :feldspar,
        :document,
        :alliance,
        :budget
      ]
    end
  end
end
