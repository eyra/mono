defmodule Systems.Storage.Yoda.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  def store(
        _endpoint,
        _panel_info,
        _data,
        _meta_data
      ) do
    Logger.warn("Yoda backend not implemented yet")
  end
end
