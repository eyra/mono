defmodule Systems.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :admin,
        :advert,
        :affiliate,
        :alliance,
        :assignment,
        :fund,
        :desktop,
        :document,
        :feldspar,
        :graphite,
        :home,
        :lab,
        :manual,
        :next_action,
        :onyx,
        :payment,
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
