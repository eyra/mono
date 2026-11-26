defmodule Mica.Seeds.Helpers do
  @moduledoc """
  Generic helpers for idempotent seed operations.

  Use these from environment-specific seed modules (`Mica.Seeds.Local`,
  `Mica.Seeds.Dev`, `Mica.Seeds.Test`, etc.) to keep get-or-create logic
  in one place.
  """

  require Logger

  alias Systems.Account
  alias Systems.License

  @doc """
  Returns the existing user with the given email or inserts a confirmed user.

  Accepts `:name` (used for both `displayname` and the profile `fullname`),
  `:creator` (boolean, default false) and `:password` (required when
  inserting). Existing users are returned untouched — the function is
  idempotent and never overwrites attributes.
  """
  def ensure_user!(email, opts) when is_binary(email) and is_list(opts) do
    case Mica.Repo.get_by(Account.User, email: email) do
      nil -> insert_user!(email, opts)
      user -> user
    end
  end

  @doc """
  Idempotently seeds a creator account. Thin wrapper over
  `ensure_user!/2` that forces `creator: true`. Use across deploy
  environments that need a known researcher account (local, dev,
  test, staging).

  Accepts the same options as `ensure_user!/2` — `:name` and
  `:password` are required.
  """
  def seed_creator!(email, opts) when is_binary(email) and is_list(opts) do
    ensure_user!(email, Keyword.put(opts, :creator, true))
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
        profile: %Account.UserProfileModel{fullname: name}
      })
      |> Mica.Repo.insert()

    if creator?, do: give_publish_license!(user)

    Logger.info("[Seeds] Created user: #{user.email} (creator=#{creator?})")
    user
  end

  # A seeded creator can publish for a year.
  defp give_publish_license!(user) do
    {:ok, _} = License.Public.grant(user, :publish, License.Public.end_date(:year_1))
  end
end
