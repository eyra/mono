defmodule Systems.Storage.System do
  use Mica.System

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

  def signal_handlers, do: [Systems.Storage.Switch]

  def rate_quotas do
    [
      [service: :azure_blob, limit: 1000, unit: :call, window: :minute, scope: :local],
      [service: :azure_blob, limit: 10_000_000, unit: :byte, window: :day, scope: :local],
      [service: :azure_blob, limit: 1_000_000_000, unit: :byte, window: :day, scope: :global],
      [service: :storage_export, limit: 6, unit: :call, window: :minute, scope: :local],
      [service: :storage_export, limit: 25, unit: :call, window: :minute, scope: :global],
      [service: :storage_export, limit: 21_474_836_480, unit: :byte, window: :day, scope: :local],
      [
        service: :storage_export,
        limit: 107_374_182_400,
        unit: :byte,
        window: :day,
        scope: :global
      ]
    ]
  end
end
