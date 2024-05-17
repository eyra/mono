defmodule Systems.Crew.RejectView do
  use CoreWeb, :live_component

  require Logger

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Selector

  alias Systems.Crew

  @impl true
  def update(%{id: id}, socket) do
    title = dgettext("link-advert", "reject.title")
    text = dgettext("link-advert", "reject.text")
    note = dgettext("link-advert", "reject.note")
    category = Crew.RejectCategories.values() |> List.first()
    categories = Crew.RejectCategories.labels(category)

    model = %Crew.RejectModel{category: category}
    changeset = Crew.RejectModel.changeset(model, :init, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        text: text,
        note: note,
        category: category,
        categories: categories,
        model: model,
        changeset: changeset
      )
      |> compose_child(:category)
    }
  end

  @impl true
  def compose(:category, %{categories: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio,
        optional?: false
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{"reject_model" => %{"message" => message}},
        %{assigns: %{model: model, category: category}} = socket
      ) do
    attrs = %{category: category, message: message}
    changeset = Crew.RejectModel.changeset(model, :submit, attrs)
    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event(
        "reject",
        %{"reject_model" => %{"message" => message}},
        %{assigns: %{model: model, category: category}} = socket
      ) do
    attrs = %{category: category, message: message}
    changeset = Crew.RejectModel.changeset(model, :submit, attrs)

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, model} ->
        {:noreply, socket |> send_event(:parent, "reject_submit", %{rejection: model})}

      {:error, %Ecto.Changeset{} = changeset} ->
        Enum.each(changeset.errors, fn {key, {error, _}} ->
          Logger.warn("Reject failed: #{key} -> #{error}")
        end)

        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, socket |> send_event(:parent, "reject_cancel")}
  end

  @impl true
  def handle_event("active_item_id", %{active_item_id: category, selector_id: :category}, socket) do
    categories = Crew.RejectCategories.labels(category)

    {
      :noreply,
      socket
      |> assign(category: category, categories: categories)
    }
  end

  defp buttons(target) do
    [
      %{
        action: %{type: :submit},
        face: %{
          type: :primary,
          label: dgettext("link-advert", "reject.button"),
          bg_color: "bg-delete"
        }
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
    <div class="p-8 bg-white shadow-floating rounded">
      <div class="flex flex-col gap-4 gap-8">
        <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
          <%= @title %>
        </div>
        <div class="text-bodymedium font-body sm:text-bodylarge">
          <%= @text %>
        </div>
        <div class="flex flex-row gap-3 items-center">
          <div class="w-6 h-6 flex-shrink-0 font-caption text-caption text-white rounded-full flex items-center bg-warning">
            <span class="text-center w-full mt-1px">!</span>
          </div>
          <div class="text-button font-button text-warning leading-6">
            <%= @note %>
          </div>
        </div>
        <.form id="reject_form" :let={form} for={@changeset} phx-change="update" phx-submit="reject" phx-target={@myself} >
          <.child name={:category} fabric={@fabric} />
          <.spacing value="M" />
          <.text_input form={form}
            field={:message}
            label_text={dgettext("link-advert", "reject.message.label")}
            debounce="0"
          />
          <.spacing value="XXS" />
          <div class="flex flex-row gap-4">
            <%= for button <- buttons(@myself) do %>
              <Button.dynamic {button} />
            <% end %>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
