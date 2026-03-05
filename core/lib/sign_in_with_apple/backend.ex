defmodule SignInWithApple.Backend do
  @moduledoc false
  alias Assent.Strategy.Apple

  def callback(config, params), do: Apple.callback(config, params)
  def authorize_url(config), do: Apple.authorize_url(config)
end
