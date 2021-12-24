defmodule Systems.Crew.TaskItemView do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Line

  prop id, :number
  prop public_id, :string, required: true
  prop message, :map
  prop buttons, :list, default: []

  defp message_color(%{type: :warning}), do: "text-warning"
  defp message_color(%{type: :alarm}), do: "text-delete"
  defp message_color(%{type: :rejected}), do: "text-delete"
  defp message_color(%{type: :attention_checks_failed}), do: "text-warning"
  defp message_color(_), do: "text-grey2"

  defp message_icon(:warning), do: "⚠️"
  defp message_icon(:alarm), do: "🚨"
  defp message_icon(:rejected), do: "🚫"
  defp message_icon(:attention_checks_failed), do: "🚦"
  defp message_icon(:not_completed), do: "🚧"

  defp message_text(%{text: text, type: type}), do: "#{message_icon(type)} #{text}"
  defp message_text(%{text: text}), do: "#{text}"

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="flex flex-row gap-8 sm:items-center">
        <div class="sm:w-32 font-body text-bodymedium sm:text-bodylarge flex-shrink-0">
          Subject {@public_id}
        </div>
        <div :if={@message} class="hidden sm:block">
          <div class={"font-body text-bodysmall sm:text-bodymedium #{message_color(@message)}"} >
            {message_text(@message)}
          </div>
        </div>
        <div class="flex-grow"></div>
        <div class="flex-wrap flex-shrink-0">
          <div class="flex flex-row gap-4">
            <DynamicButton :for={button <- @buttons} vm={button} />
          </div>
        </div>
      </div>
      <div class="sm:hidden">
        <Spacing value="XS" />
        <div :if={@message} class="flex-wrap">
          <div class={"font-body text-bodysmall #{message_color(@message)}"} >
            {message_text(@message)}
          </div>
        </div>

        <Spacing value="XS" />
        <Line />
      </div>
    </div>
    """
  end
end

defmodule Systems.Crew.TaskItemView.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Crew.TaskItemView,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Task item used on campaign monitor",
    height: "640px",
    direction: "vertical",
    container: {:div, class: ""}

  require Logger

  alias Frameworks.Pixel.Text.Title3

  def render(assigns) do
    ~F"""
    <Title3>Waitinglist</Title3>

    <TaskItemView :props={
      public_id: "1234",
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]
    } />

    <div class="mb-12"></div>

    <Title3>Attention</Title3>

    <TaskItemView :props={
      public_id: "777",
      message: %{type: :warning, text: "Got rejected last assignment"},
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]
    } />

    <div class="mb-6"></div>

    <TaskItemView :props={
      public_id: "112",
      message: %{type: :alarm, text: "Completed far below estimated duration"},
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]
    } />

    <div class="mb-12"></div>

    <Title3>Rejected</Title3>

    <TaskItemView :props={
      public_id: "63",
      message: %{type: :attention_checks_failed, text: "Attention checks failed"},
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]
    } />

    <div class="mb-6"></div>

    <TaskItemView :props={
      public_id: "282",
      message: %{type: :not_completed, text: "Not completed"},
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]
    } />

    <div class="mb-6"></div>

    <TaskItemView :props={
      public_id: "1349",
      message: %{type: :rejected, text: "Rejected because of other reasons"},
      buttons: [
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]
    } />

    """
  end

  def handle_event("accept", _, socket) do
    Logger.info("Accept")
    {:noreply, socket}
  end

  def handle_event("reject", _, socket) do
    Logger.info("Reject")
    {:noreply, socket}
  end

end
