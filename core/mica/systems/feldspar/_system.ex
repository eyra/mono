defmodule Systems.Feldspar.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Feldspar.Routes
      Systems.Feldspar.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.Feldspar.AppPage, [:visitor, :member]}
    ]
  end

  def signal_handlers, do: [Systems.Feldspar.Switch]

  # Clean up old data donation files every hour
  def oban_crons,
    do: [data_donation_cleanup: {"0 * * * *", Systems.Feldspar.DataDonationCleanupWorker}]
end
