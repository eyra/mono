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

  @spec handler(String.t()) :: {:ok, module()} | {:error, :unknown_provider}
  def handler(provider) do
    provider_module = Module.concat(Systems.Payment.Provider, String.upcase(provider))
    module = Module.concat(provider_module, Webhook)

    if Code.ensure_loaded?(module) and function_exported?(module, :verify_and_parse, 1) do
      {:ok, module}
    else
      {:error, :unknown_provider}
    end
  end
end
