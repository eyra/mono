defmodule Systems.Crew.RejectView do
  use CoreWeb, :live_component

  require Logger

  alias Frameworks.Pixel.Selector
  import Frameworks.Pixel.Form

  alias Systems.{
    Crew
  }

  import CoreWeb.Gettext

  @impl true
  def update(
        %{active_item_id: category, selector_id: :category},
        socket
      ) do
    categories = Crew.RejectCategories.labels(category)

    {
      :ok,
      socket
      |> assign(category: category, categories: categories)
    }
  end

  @impl true
  def update(%{id: id, target: target}, socket) do
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
        target: target,
        title: title,
        text: text,
        note: note,
        category: category,
        categories: categories,
        model: model,
        changeset: changeset
      )
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
        %{assigns: %{model: model, target: target, category: category}} = socket
      ) do
    attrs = %{category: category, message: message}
    changeset = Crew.RejectModel.changeset(model, :submit, attrs)

    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, model} ->
        update_target(target, %{reject: :submit, rejection: model})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        Enum.each(changeset.errors, fn {key, {error, _}} ->
          Logger.warn("Reject failed: #{key} -> #{error}")
        end)

        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("cancel", _params, %{assigns: %{target: target}} = socket) do
    update_target(target, %{reject: :cancel})
    {:noreply, socket}
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

  # data(title, :string)
  # data(text, :string)
  # data(note, :string)
  # data(message_input_label, :string)
  # data(categories, :list)
  # data(category, :atom)
  # data(model, :map)
  # data(changeset, :map)

  attr(:target, :map, required: true)

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
          <.live_component
          module={Selector}
            id={:category}
            items={@categories}
            type={:radio}
            optional?={false}
            parent={%{type: __MODULE__, id: @id}}
          />
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
