defmodule Link.Repo do
  use Ecto.Repo,
    otp_app: :link,
    adapter: Ecto.Adapters.Postgres
end
