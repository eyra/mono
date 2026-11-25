defmodule Mica.Repo.Migrations.DeleteEmailChangeTokens do
  use Ecto.Migration

  # /user/settings no longer changes an email address, so nothing reads the tokens
  # its confirmation links used (context "change:<old email>", sent_to the new
  # address). They can't be used any more and only keep that address.
  def up do
    execute("DELETE FROM users_tokens WHERE context LIKE 'change:%'")
  end

  # The deleted tokens can't be restored; older code then sends a new link.
  def down, do: :ok
end
