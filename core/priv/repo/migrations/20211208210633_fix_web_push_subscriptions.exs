defmodule Core.Repo.Migrations.FixWebPushSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:web_push_subscriptions) do
      modify(:endpoint, :text)
    end
  end
end
