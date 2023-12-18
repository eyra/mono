defmodule Systems.Crew.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal
  alias Systems.Crew

  @impl true
  def intercept(
        {:crew_member, _} = signal,
        %{crew_member: %{crew_id: crew_id}} = message
      ) do
    crew = Crew.Public.get!(crew_id)

    dispatch!(
      {:crew, signal},
      Map.merge(message, %{crew: crew})
    )
  end
end
