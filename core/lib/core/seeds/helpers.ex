defmodule Core.Seeds.Helpers do
  @moduledoc """
  Generic helpers for idempotent seed operations.

  Use these from environment-specific seed modules (`Core.Seeds.Local`,
  `Core.Seeds.Dev`, `Core.Seeds.Test`, etc.) to keep get-or-create logic
  in one place.
  """

  require Logger

  alias Systems.Account

  @doc """
  Returns the existing user with the given email or inserts a confirmed user.

  Accepts `:name` (used for both `displayname` and the profile `fullname`),
  `:creator` (boolean, default false) and `:password` (required when
  inserting). Existing users are returned untouched — the function is
  idempotent and never overwrites attributes.
  """
  def ensure_user!(email, opts) when is_binary(email) and is_list(opts) do
    case Core.Repo.get_by(Account.User, email: email) do
      nil -> insert_user!(email, opts)
      user -> user
    end
  end

  defp insert_user!(email, opts) do
    password = Keyword.fetch!(opts, :password)
    name = Keyword.fetch!(opts, :name)
    creator? = Keyword.get(opts, :creator, false)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    {:ok, user} =
      %Account.User{}
      |> Ecto.Changeset.change(%{
        email: email,
        hashed_password: Bcrypt.hash_pwd_salt(password),
        displayname: name,
        creator: creator?,
        confirmed_at: now,
        verified_at: now,
        profile: %Account.UserProfileModel{fullname: name}
      })
      |> Core.Repo.insert()

    Logger.info("[Seeds] Created user: #{user.email} (creator=#{creator?})")
    user
  end
end
