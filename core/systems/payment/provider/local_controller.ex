defmodule Systems.Payment.Provider.LocalController do
  use CoreWeb, {:controller, [formats: [:html]]}

  require Logger

  import Ecto.Query

  alias Systems.Budget

  def pay(conn, %{"uid" => uid}) do
    html(conn, """
    <html>
    <head><title>Local Payment Simulator</title></head>
    <body style="font-family: sans-serif; max-width: 500px; margin: 80px auto; text-align: center;">
      <h1>Payment Simulator</h1>
      <p>Transaction: <code>#{uid}</code></p>
      <br/>
      <form method="post" action="/payment/local/#{uid}/complete">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <button type="submit" data-testid="local-payment-complete-button" style="padding: 12px 24px; font-size: 16px; background: #22c55e; color: white; border: none; border-radius: 6px; cursor: pointer;">
          Complete Payment (Success)
        </button>
      </form>
      <br/>
      <form method="post" action="/payment/local/#{uid}/fail">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <button type="submit" data-testid="local-payment-fail-button" style="padding: 12px 24px; font-size: 16px; background: #ef4444; color: white; border: none; border-radius: 6px; cursor: pointer;">
          Fail Payment
        </button>
      </form>
    </body>
    </html>
    """)
  end

  def complete(conn, %{"uid" => uid}) do
    transaction = Budget.Public.get_transaction_by_provider_uid!(uid)
    return_path = return_path(transaction)

    case Budget.Public.complete_transaction(uid) do
      {:ok, _} ->
        redirect(conn, to: return_path)

      {:error, reason} ->
        Logger.warning("[Payment.Local] Complete failed: #{inspect(reason)}")
        redirect(conn, to: return_path)
    end
  end

  def fail(conn, %{"uid" => uid}) do
    transaction = Budget.Public.get_transaction_by_provider_uid!(uid)
    Budget.Public.fail_transaction(uid)
    redirect(conn, to: return_path(transaction))
  end

  defp return_path(%{target_fund_id: fund_id}) do
    case Core.Repo.one(
           from(a in Systems.Assignment.Model, where: a.fund_id == ^fund_id, select: a.id)
         ) do
      nil -> "/"
      assignment_id -> "/assignment/#{assignment_id}/content"
    end
  end
end
