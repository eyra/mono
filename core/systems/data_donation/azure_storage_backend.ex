defmodule Systems.DataDonation.AzureStorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  require Timex.Translator

  alias Azurex.Blob

  def store(
        %{"participant" => participant, "platform" => platform, "timestamp" => timestamp} =
          _state,
        %{"storage_info" => %{"key" => key}} = _vm,
        data
      ) do
    Timex.Translator.with_locale "en" do
      path = path(key, participant, platform, timestamp)
      Blob.put_blob(path, data, "text/plain")
    end
  end

  def path(key, participant, platform, timestamp) do
    "#{key}/#{participant}/#{platform}-#{timestamp}.json"
  end
end
