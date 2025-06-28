defmodule Frameworks.Signal.Public do
  use Core, :public
  require Logger

  import Frameworks.Utility.PrettyPrint

  alias Frameworks.Signal.Private

  def dispatch(signal, message) do
    message = Map.put_new(message, :from_pid, self())

    case Private.dispatch(signal, message) do
      {:error, _} = error ->
        Logger.warning(
          "Unhandeld signal: #{pretty_print(signal)} => #{pretty_print(Map.keys(message))}, FROM: #{inspect(Map.get(message, :from_pid))}"
        )

        error

      other ->
        other
    end
  end

  @doc """
  # Deprecated, replaced by control flow in intercept/2
  #
  # Implement intercept/2 in your Signal Handler like this instead:
  #
  # ```elixir
  # def intercept({my_entity, :updated}, %{my_entity: my_entity}) do
  #   my_tool = get_my_tool_by_my_entity!(my_entity)
  #   {:continue, :my_tool, my_tool}
  # end
  # ```
  """
  def dispatch!(signal, message) do
    dispatch(signal, message)
  end

  @doc """
  Send a signal as part of an Ecto Multi.
  It automatically merges the message with the multi
  changes.
  """
  def multi_dispatch(multi, signal, message \\ %{}) when is_map(message) do
    Ecto.Multi.run(multi, :dispatch_signal, fn _, updates ->
      :ok = dispatch(signal, Map.merge(updates, message))
      {:ok, message}
    end)
  end
end
