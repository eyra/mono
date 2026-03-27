defmodule Core.Repo.Migrations.ConfirmExistingAffiliateUsers do
  use Ecto.Migration

  def up do
    # Auto-confirm all existing affiliate users
    # Affiliate users have synthetic emails and cannot verify via email confirmation
    execute("""
    UPDATE users
    SET confirmed_at = NOW()
    WHERE id IN (
      SELECT user_id FROM affiliate_user
    )
    AND confirmed_at IS NULL
    """)
  end

  def down do
    # No-op: we don't want to un-confirm users on rollback
    :ok
  end
end
