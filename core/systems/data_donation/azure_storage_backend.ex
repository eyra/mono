defmodule Systems.DataDonation.AzureStorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  require Timex.Translator

  alias Azurex.Blob

  def store(
        %{"participant" => participant, "key" => donation_key},
        %{"storage_info" => %{"key" => root_key}},
        data
      ) do
    Timex.Translator.with_locale "en" do
      path = path(root_key, participant, donation_key)
      Blob.put_blob(path, data, "text/plain")
    end
  end

  def path(root_key, participant, donation_key) do
    "#{root_key}/#{participant}/#{donation_key}.json"
  end
end
