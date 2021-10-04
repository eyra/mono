defmodule Core.Repo.Migrations.SetupCascadeDeleteForUsers do
  use Ecto.Migration

  def change do
    for table <-
          ~w(next_actions google_sign_in_users sign_in_with_apple_users surfconext_users user_profiles users_tokens web_push_subscriptions) do
      drop(constraint(table, "#{table}_user_id_fkey"))

      alter table(table) do
        modify(:user_id, references(:users, on_delete: :delete_all))
      end
    end
  end
end
