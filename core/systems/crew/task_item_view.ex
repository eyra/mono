defmodule Systems.Crew.TaskItemView do
  use CoreWeb.UI.Component

  prop(id, :number)
  prop(public_id, :string, required: true)
  prop(description, :string)
  prop(message, :map)
  prop(buttons, :list, default: [])

  defp message_color(%{type: :warning}), do: "text-grey1"
  defp message_color(%{type: :alarm}), do: "text-delete"
  defp message_color(_), do: "text-grey2"

  defp message_text(%{text: text}), do: "#{text}"
  defp message_text(_), do: ""

  @impl true
  def render(assigns) do
    ~F"""
    <tr class="h-12">
      <td class="pl-0 font-body text-bodymedium sm:text-bodylarge">
        Subject {@public_id}
      </td>
      <td :if={@description} class="pl-8 font-body text-bodysmall sm:text-bodymedium text-grey1">
        {@description}
      </td>
      <td class={"pl-8 font-body text-bodysmall sm:text-bodymedium #{message_color(@message)}"}>
        {message_text(@message)}
      </td>
      <td class="pl-12">
        <div class="flex flex-row gap-4">
          <DynamicButton :for={button <- @buttons} vm={button} />
        </div>
      </td>
    </tr>
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

    <TaskItemView
      public_id="1234"
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]}
    />

    <div class="mb-12" />

    <Title3>Attention</Title3>

    <TaskItemView
      public_id="777"
      message={%{type: :warning, text: "Got rejected last assignment"}}
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]}
    />

    <div class="mb-6" />

    <TaskItemView
      public_id="112"
      message={%{type: :alarm, text: "Completed far below estimated duration"}}
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        },
        %{
          action: %{type: :send, item: 1, target: "", event: "reject"},
          face: %{type: :icon, icon: :reject}
        }
      ]}
    />

    <div class="mb-12" />

    <Title3>Rejected</Title3>

    <TaskItemView
      public_id="63"
      message={%{type: :attention_checks_failed, text: "Attention checks failed"}}
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]}
    />

    <div class="mb-6" />

    <TaskItemView
      public_id="282"
      message={%{type: :not_completed, text: "Not completed"}}
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]}
    />

    <div class="mb-6" />

    <TaskItemView
      public_id="1349"
      message={%{type: :rejected, text: "Rejected because of other reasons"}}
      buttons={[
        %{
          action: %{type: :send, item: 1, target: "", event: "accept"},
          face: %{type: :icon, icon: :accept}
        }
      ]}
    />
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
