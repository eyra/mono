defmodule Frameworks.Promotable.Director do
  @type promotable :: map()
  @type error :: atom()
  @type user :: map()

  @callback reward_value(promotable) :: integer()
  @callback validate_open(promotable, user) :: :ok | {:error, error}
end
