defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :admin,
        :advert,
        :alliance,
        :assignment,
        :budget,
        :desktop,
        :document,
        :feldspar,
        :graphite,
        :home,
        :lab,
        :next_action,
        :notification,
        :org,
        :pool,
        :project,
        :promotion,
        :storage,
        :support
      ]
    end
  end
end
