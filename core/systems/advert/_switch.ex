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

  defp handle(
         {:advert, _},
         %{
           advert:
             %Advert.Model{
               id: id,
               promotion_id: promotion_id,
               promotion: promotion,
               assignment_id: assignment_id
             } = advert,
           from_pid: from_pid
         }
       ) do
    update(Promotion.LandingPage, promotion_id, promotion, from_pid)
    update(Assignment.LandingPage, assignment_id, advert, from_pid)
    update(Advert.ContentPage, id, advert, from_pid)
  end

  defp handle({_, _}, _), do: nil

  def update(page, id, model, from_pid) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
