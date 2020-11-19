defmodule GreenLight.Config do
  defmodule ConfigError do
    @moduledoc false
    defexception [:message]
  end

  @doc """
  Raise a ConfigError.
  """
  def raise_error(message) do
    raise ConfigError, message: message
  end

  def repo!(config) do
    Keyword.get(config, :repo) ||
      raise_error("Required `:repo` option not set.")
  end

  def roles!(config) do
    Keyword.get(config, :roles) ||
      raise_error("Required `:roles` option not set.")
  end

  def role_assignment_schema!(config) do
    Keyword.get(config, :role_assignment_schema) ||
      raise_error("Required `:role_assignment_schema` option not set.")
  end
end
