defmodule Link.Users do
  @moduledoc """
  The Ssers context.
  """
  use Pow.Ecto.Context,
    repo: Link.Repo,
    user: Link.Users.User

  def create(params) do
    pow_create(params)
  end
end
