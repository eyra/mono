defmodule Systems.Account.Identity.Apple.Backend do
  def callback(config, params), do: Assent.Strategy.Apple.callback(config, params)
  def authorize_url(config), do: Assent.Strategy.Apple.authorize_url(config)
end
