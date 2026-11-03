defmodule Systems.Fund.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Fund.Routes
      Systems.Fund.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Fund.FundingPage, [:admin, :creator]}
      ]
    end
  end

  def oban_crons do
    [
      # Fail pending pay-in transactions older than 15 minutes
      pay_in_expiration: {"* * * * *", Systems.Fund.PayInExpirationWorker},
      # Approve pending rewards every hour
      auto_approve: {"0 * * * *", Systems.Fund.AutoApproveWorker}
    ]
  end
end
