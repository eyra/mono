defmodule Systems.Advert.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Advert,
    Promotion,
    Assignment
  }

  @impl true
  def intercept({:assignment, _} = signal, %{assignment: assignment} = message) do
    if advert = Advert.Public.get_by_assignment(assignment, Advert.Model.preload_graph(:down)) do
      handle(signal, message)
      dispatch!({:advert, signal}, Map.merge(message, %{advert: advert}))
    end

    :ok
  end

  @impl true
  def intercept({:promotion, _} = signal, %{promotion: promotion} = message) do
    if advert = Advert.Public.get_by_promotion(promotion, Advert.Model.preload_graph(:down)) do
      dispatch!({:advert, signal}, Map.merge(message, %{advert: advert}))
    end

    :ok
  end

  @impl true
  def intercept({:advert, _} = signal, message) do
    handle(signal, message)
    :ok
  end

  @impl true
  def intercept({:user_profile, _} = signal, message) do
    handle(signal, message)
    :ok
  end

  # HANDLE

  defp handle({:user_profile, :updated}, %{user: user, user_changeset: user_changeset}) do
    if Map.has_key?(user_changeset.changes, :coordinator) do
      new_value = user_changeset.changes.coordinator
      Advert.Public.update_coordinator_role(user, new_value)
    end
  end

  defp handle(
         {:advert, event},
         %{
           advert:
             %Advert.Model{
               id: id,
               promotion_id: promotion_id,
               assignment_id: assignment_id
             } = advert,
           from_pid: from_pid
         }
       ) do
    if event == :created do
      Advert.Public.assign_coordinators(advert)
    else
      update(Promotion.LandingPage, promotion_id, advert, from_pid)
      update(Assignment.LandingPage, assignment_id, advert, from_pid)
      update(Advert.ContentPage, id, advert, from_pid)
    end
  end

  defp handle({_, _}, _), do: nil

  def update(page, id, %Advert.Model{} = advert, from_pid) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: advert, from_pid: from_pid})
  end
end
