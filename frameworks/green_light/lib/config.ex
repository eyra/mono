defmodule GreenLight.Config do
  defmodule ConfigError do
    @moduledoc false
    defexception [:message]
  end

  def repo!(config) do
    Keyword.get(config, :repo) ||
      raise ConfigError, message: "Required `:repo` option not set."
  end

  def roles!(config) do
    Keyword.get(config, :roles) ||
      raise ConfigError, message: "Required `:roles` option not set."
  end

  def role_assignment_schema!(config) do
    Keyword.get(config, :role_assignment_schema) ||
      raise ConfigError, message: "Required `:role_assignment_schema` option not set."
  end
end
