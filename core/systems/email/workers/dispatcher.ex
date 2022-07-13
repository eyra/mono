defmodule Systems.Email.Dispatcher do
  use Oban.Worker, queue: :email_dispatchers
  alias Ecto.Multi
  alias Core.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"to" => to} = args
      }) do
    IO.puts("#{__MODULE__} perform")

    Multi.new()
    |> dispatch_multi(0, to, args)
    |> Repo.transaction()

    :ok
  end

  defp dispatch_multi(multi, _, [], _), do: multi

  defp dispatch_multi(multi, index, [to | tail], args) do
    multi
    |> dispatch_multi(index, to, args)
    |> dispatch_multi(index + 1, tail, args)
  end

  defp dispatch_multi(multi, index, to, args) when is_binary(to) do
    email = %{args | "to" => [to]}
    Oban.insert(multi, "job-#{index}", Systems.Email.Delivery.new(email))
  end
end
