defmodule Systems.Storage.System do
  use Core.System

  def routes do
    quote do
      require Systems.Storage.Routes
      Systems.Storage.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Storage.EndpointContentPage, [:owner]}
      ]
    end
  end
end
