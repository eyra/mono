defmodule Core.Repo.Migrations.RenameBudgetToFund do
  use Ecto.Migration

  def up do
    # Rename budgets table to funds
    rename table(:budgets), to: table(:funds)

    # Rename budget_rewards table to fund_rewards
    rename table(:budget_rewards), to: table(:fund_rewards)

    # Rename budget_id column in fund_rewards to fund_id
    rename table(:fund_rewards), :budget_id, to: :fund_id

    # Rename budget_id column in assignments to fund_id
    rename table(:assignments), :budget_id, to: :fund_id
  end

  def down do
    rename table(:assignments), :fund_id, to: :budget_id
    rename table(:fund_rewards), :fund_id, to: :budget_id
    rename table(:fund_rewards), to: table(:budget_rewards)
    rename table(:funds), to: table(:budgets)
  end
end
