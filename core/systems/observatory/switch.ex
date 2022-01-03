defmodule Systems.Observatory.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Observatory
  }

  def dispatch(%{page: page}, %{id: id} = message) do
    Observatory.Context.local_dispatch(page, [id], message)
  end
end
