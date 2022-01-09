defmodule BankingClient do
  @behaviour Systems.Banking.Backend

  @impl Systems.Banking.Backend
  def list_payments(cursor) do
    message =
      if is_nil(cursor) do
        %{call: :list_payments}
      else
        %{call: :list_payments, cursor: cursor}
      end

    api().send_message(message)
    |> BankingClient.ListPaymentsResponse.conform()
  end

  @impl Systems.Banking.Backend
  def submit_payment(_payment) do
    {:error, :not_implemented}
  end

  defp api do
    Application.fetch_env!(:core, BankingClient)
    |> Keyword.get(:client, BankingClient.ProxyClient)
  end
end
