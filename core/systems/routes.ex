defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :admin,
        :advert,
        :affiliate,
        :alliance,
        :assignment,
        :budget,
        :desktop,
        :document,
        :feldspar,
        :graphite,
        :home,
        :lab,
        :manual,
        :next_action,
        :notification,
        :onyx,
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
