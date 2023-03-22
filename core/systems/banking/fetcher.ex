defmodule Systems.Banking.Fetcher do
  use GenServer
  import Ecto.Query
  require Logger

  alias Core.Repo

  alias Systems.{
    Banking
  }

  def start_link(init_args) do
    currency = Keyword.get(init_args, :currency, :euro)
    name = String.to_atom("#{__MODULE__}.#{currency}")
    GenServer.start_link(__MODULE__, init_args, name: name)
  end

  @impl true
  def init(args) do
    interval = Keyword.get(args, :interval, 5 * 60 * 1000)
    strategy = Keyword.get(args, :strategy, nil)
    currency = Keyword.get(args, :currency, nil)
    processor = %Banking.Processor{strategy: strategy, currency: currency}

    state = %{
      interval: interval,
      processor: processor
    }

    schedule_fetch(state)

    {
      :ok,
      state
    }
  end

  @impl true
  def handle_info(:fetch, state) do
    fetch(state)
    schedule_fetch(state)

    {
      :noreply,
      state
    }
  end

  defp schedule_fetch(%{interval: interval}) do
    Process.send_after(self(), :fetch, interval)
  end

  def fetch(%{processor: processor}) do
    %{cursor: new_cursor, payments: payments} =
      last_cursor()
      |> Banking.Public.list_payments()

    payment_count = Enum.count(payments)
    Logger.info("[#{__MODULE__}] Fetched #{payment_count} payments")

    unless Enum.empty?(payments) do
      Enum.each(payments, &Banking.Processor.next(processor, &1))
      update_cursor(new_cursor, payment_count)
    end
  end

  def update_cursor(new_cursor, payment_count) do
    Repo.insert!(%Banking.MarkerModel{
      marker: new_cursor,
      payment_count: payment_count
    })
  end

  def last_cursor do
    from(mm in Banking.MarkerModel,
      select: mm.marker,
      order_by: [desc: mm.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end
end
