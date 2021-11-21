defmodule Systems.Crew.RejectView do
  use Surface.LiveComponent

  alias Frameworks.Pixel.Button.DynamicButton
  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Form.{Form, TextInput}
  alias Frameworks.Pixel.Spacing

  alias Systems.{
    Crew
  }

  import CoreWeb.Gettext

  prop target, :map, required: true

  data title, :string
  data text, :string
  data note, :string
  data message_input_label, :string
  data categories, :list
  data category, :atom
  data model, :map
  data changeset, :map
  data focus, :string, default: ""

  def update(%{active_item_id: active_item_id, selector_id: :category}, socket) do
    category =
      case active_item_id do
        nil -> nil
        item when is_atom(item) -> Atom.to_string(item)
        _ -> active_item_id
      end

    {
      :ok,
      socket
      |> assign(category: category, focus: :category)
    }
  end

  def update(%{id: id, target: target}, socket) do

    title = dgettext("link-campaign", "reject.title")
    text = dgettext("link-campaign", "reject.text")
    note = dgettext("link-campaign", "reject.note")
    category = Crew.RejectCategories.values() |> List.first()
    categories = Crew.RejectCategories.labels(category)

    model = %Crew.RejectModel{category: category}
    changeset = Crew.RejectModel.changeset(model, :init, %{})

    {
      :ok,
      socket |> assign(
        id: id,
        target: target,
        title: title,
        text: text,
        note: note,
        categories: categories,
        model: model,
        changeset: changeset
      )
    }
  end

  def handle_event("update", %{"reject_model" => reject_model}, %{assigns: %{model: model}} = socket) do
      changeset = Crew.RejectModel.changeset(model, :submit, reject_model)
      {:noreply, socket |> assign(changeset: changeset)}
  end

  def handle_event("reject", %{"reject_model" => reject_model}, %{assigns: %{model: model, target: target}} = socket) do
    changeset = Crew.RejectModel.changeset(model, :submit, reject_model)

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, model} ->
        send_update(target.type, id: target.id, reject: :submit, rejection: model)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(focus: "", changeset: changeset)}
    end
  end

  def handle_event("cancel", _params, %{assigns: %{target: target}} = socket) do
    send_update(target.type, id: target.id, reject: :cancel)
    {:noreply, socket}
  end

  @impl true
  def handle_event("focus", %{"field" => field}, socket) do
    {:noreply, socket |> assign(focus: field)}
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    {:noreply, socket |> assign(focus: "")}
  end

  defp buttons(target) do
    [
      %{
        action: %{type: :submit},
        face: %{type: :primary, label: dgettext("link-campaign", "reject.button"), bg_color: "bg-delete"}
      },
      %{
        action: %{type: :send, event: "cancel", target: target},
        face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="p-8 bg-white shadow-2xl rounded" phx-click="reset_focus" phx-target={{@myself}}>
        <div class="flex flex-col gap-4 gap-8">
          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            {{@title}}
          </div>
          <div class="text-bodymedium font-body sm:teçxt-bodylarge">
            {{@text}}
          </div>
          <div class="flex flex-row gap-3 items-center">
            <div class="w-6 h-6 flex-shrink-0 font-caption text-caption text-white rounded-full flex items-center bg-warning">
              <span class="text-center w-full mt-1px">!</span>
            </div>
            <div class="text-button font-button text-warning leading-6">
              {{@note}}
            </div>
          </div>
          <Form id="reject_form" changeset={{@changeset}} change_event="update" submit="reject" target={{@myself}} focus={{@focus}} >
            <Selector id={{:category}} items={{ @categories }} type={{:radio}} optional?={{false}} parent={{ %{type: __MODULE__, id: @id} }}/>
            <Spacing value="M"/>
            <TextInput field={{:message}} label_text={{dgettext("link-campaign", "reject.message.label")}} debounce="0"/>
            <Spacing value="XXS" />
            <div class="flex flex-row gap-4">
              <DynamicButton :for={{ button <- buttons(@myself) }} vm={{ button }} />
            </div>
          </Form>
        </div>
      </div>
    """
  end
end

defmodule Systems.Crew.RejectView.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Crew.RejectView,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Reject view",
    height: "640px",
    container: {:div, class: ""}

  def render(assigns) do
    ~H"""
    <RejectView id={{ :reject_view_example }} target={{ %{type: __MODULE__, id: @id} }} />
    """
  end

  def update(%{reject: :submit, rejection: rejection}, socket) do
    IO.puts("submit: rejection=#{rejection}")
    {:ok, socket}
  end

  def update(%{reject: :cancel}, socket) do
    IO.puts("cancel")
    {:ok, socket}
  end

end
