defmodule Systems.Payment.Webhook do
  alias Systems.Payment.Error

  @type event :: %{
          uid: String.t(),
          type: String.t(),
          object_uid: String.t(),
          object_type: String.t(),
          object_url: String.t(),
          parent_uid: String.t() | nil,
          parent_type: String.t() | nil
        }

  @callback verify_and_parse(Plug.Conn.t()) :: {:ok, event()} | {:error, Error.t()}

  @providers %{
    "opp" => Systems.Payment.Provider.OPP.Webhook
  }

  @spec handler(String.t()) :: {:ok, module()} | {:error, :unknown_provider}
  def handler(provider) do
    case Map.fetch(@providers, provider) do
      {:ok, module} -> {:ok, module}
      :error -> {:error, :unknown_provider}
    end
  end
end
