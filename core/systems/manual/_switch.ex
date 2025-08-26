defmodule Systems.Manual.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Manual

  def intercept({:userflow_step, _} = signal, %{userflow_step: userflow_step} = message) do
    if chapter = Manual.Public.get_chapter_by_step(userflow_step) do
      dispatch!({:manual_chapter, signal}, Map.put(message, :manual_chapter, chapter))
    end

    if page = Manual.Public.get_page_by_step(userflow_step) do
      dispatch!({:manual_page, signal}, Map.put(message, :manual_page, page))
    end

    :ok
  end

  def intercept({:manual_page, _} = signal, %{manual_page: manual_page} = message) do
    chapter = Manual.Public.get_chapter!(manual_page.chapter_id)
    dispatch!({:manual_chapter, signal}, Map.put(message, :manual_chapter, chapter))

    :ok
  end

  def intercept({:manual_chapter, _} = signal, %{manual_chapter: manual_chapter} = message) do
    manual = Manual.Public.get_manual!(manual_chapter.manual_id)
    dispatch!({:manual, signal}, Map.put(message, :manual, manual))

    :ok
  end

  def intercept({:manual, _} = signal, %{manual: manual} = message) do
    if manual_tool = Manual.Public.get_tool_by_manual(manual) do
      dispatch!({:manual_tool, signal}, Map.put(message, :manual_tool, manual_tool))
    end

    handle(signal, message)

    :ok
  end

  defp handle({:manual, _}, %{manual: manual, from_pid: from_pid}) do
    update_pages(manual, from_pid)
  end

  defp update_pages(%Manual.Model{} = manual, from_pid) do
    [
      Manual.Builder.PublicPage
    ]
    |> Enum.each(&update_page(&1, manual, from_pid))
  end

  defp update_page(page, model, from_pid) do
    dispatch!({:page, page}, %{id: model.id, model: model, from_pid: from_pid})
  end
end
