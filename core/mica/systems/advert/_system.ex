defmodule Systems.Advert.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Advert.Routes
      Systems.Advert.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Advert.Model, [:visitor, :member]},
        {Systems.Advert.ContentPage, [:owner]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Advert.Switch]

  def oban_crons, do: [advert_expiration: {"*/5 * * * *", Systems.Advert.ExpirationWorker}]
end
