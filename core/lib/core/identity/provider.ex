defmodule Core.Identity.Provider do
  @moduledoc """
  Behaviour for Identity Provider satellite modules (SURFconext, Google, …).

  An implementation owns the satellite Ecto schema (one row per linked
  identity) and the proprietary shape of the IdP's `userinfo` payload.
  The orchestrator in `Core.Identity` is the only caller of these
  callbacks; it relies on each implementation being thin and stateless
  beyond the satellite row.

  See `Core.SurfConext` and `GoogleSignIn` for the canonical implementations.
  """

  alias Systems.Account.User

  @typedoc """
  Normalized Account.User attrs derived from a proprietary `userinfo` map.

  Keys mirror what `Systems.Account.User.sso_changeset/2` casts — adding
  a new key here means widening the cast list there too. `:email` is the
  only required key; the rest are optional and may be omitted by an IdP
  that doesn't carry them.
  """
  @type user_attrs :: %{
          required(:email) => String.t(),
          optional(:displayname) => String.t(),
          optional(:creator) => boolean(),
          optional(:confirmed_at) => NaiveDateTime.t(),
          optional(:verified_at) => NaiveDateTime.t(),
          optional(:fullname) => String.t(),
          optional(:title) => String.t(),
          optional(:photo_url) => String.t()
        }

  @doc "Translate a proprietary IdP `userinfo` map into normalized user attrs."
  @callback user_attrs(userinfo :: map()) :: user_attrs()

  @doc "Return the satellite row for `user`, or `nil` if none exists."
  @callback get(user :: User.t()) :: struct() | nil

  @doc "Insert a new satellite row linked to `user` from `userinfo`."
  @callback attach(user :: User.t(), userinfo :: map()) ::
              {:ok, struct()} | {:error, Ecto.Changeset.t()}

  @doc "Refresh the satellite row for `user` with the latest `userinfo`. The row MUST exist."
  @callback refresh(user :: User.t(), userinfo :: map()) :: struct()
end
