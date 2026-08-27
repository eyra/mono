defmodule BankingClient do
  @moduledoc false
  @behaviour Systems.Banking.Backend

  alias Systems.Banking.Backend

  @impl Backend
  def list_payments(cursor) do
    message =
      if is_nil(cursor) do
        %{call: :list_payments}
      else
        %{call: :list_payments, cursor: cursor}
      end

    message
    |> api().send_message()
    |> BankingClient.ListPaymentsResponse.conform()
  end

  @impl Backend
  def submit_payment(_payment) do
    {:error, :not_implemented}
  end

  defp api do
    :core
    |> Application.fetch_env!(BankingClient)
    |> Keyword.get(:client, BankingClient.ProxyClient)
  end
end
