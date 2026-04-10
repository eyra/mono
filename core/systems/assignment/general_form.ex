defmodule Systems.Assignment.GeneralForm do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form

  alias Systems.Assignment

  @impl true
  def update(
        %{
          id: id,
          entity: entity,
          viewport: viewport,
          breakpoint: breakpoint,
          content_flags: content_flags
        },
        socket
      ) do
    changeset = Assignment.InfoModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      )
      |> update_language_items()
    }
  end

  def update_language_items(
        %{
          assigns: %{
            entity: %{language: language},
            content_flags: content_flags
          }
        } = socket
      ) do
    language_mode = determine_language_mode(content_flags)
    resolved_language = resolve_language(language, language_mode)

    assign(socket,
      language_items: Assignment.Languages.labels(resolved_language),
      language_mode: language_mode
    )
  end

  # Language modes: either :free_choice or :fixed_nl
  defp determine_language_mode(content_flags) do
    if Map.get(content_flags, :language_fixed_nl, false) do
      :fixed_nl
    else
      :free_choice
    end
  end

  defp resolve_language(_, :fixed_nl), do: :nl
  defp resolve_language(language, :free_choice), do: language || Assignment.Languages.default()

  # Handle Events

  @impl true
  def handle_event(
        "update",
        %{source: %{name: :language_selector}, status: language},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, %{language: language})
    }
  end

  @impl true
  def handle_event("save", %{"info_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Assignment.InfoModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_general"} :let={form} for={@changeset} phx-submit="save" phx-change="save" phx-target={@myself}>
        <%= if show_expected?(@content_flags) and paid_slots?(@content_flags) do %>
          <.render_subject_count_display form={form} />
        <% end %>
        <%= if show_expected?(@content_flags) and not paid_slots?(@content_flags) do %>
          <.render_subject_count_field form={form} />
        <% end %>
        <.render_language_field :if={show_language_field?(@content_flags)}
          form={form}
          language_items={@language_items}
          language_mode={@language_mode} />
      </.form>
    </div>
    """
  end

  defp show_expected?(content_flags), do: Map.get(content_flags, :expected, false)
  defp paid_slots?(content_flags), do: Map.get(content_flags, :paid_slots, false)

  defp render_subject_count_field(assigns) do
    ~H"""
    <.number_input
      form={@form}
      field={:subject_count}
      label_text={dgettext("eyra-assignment", "settings.subject_count.expected_label")} />
    """
  end

  defp render_subject_count_display(assigns) do
    count = input_value(assigns.form, :subject_count) || 0
    assigns = assign(assigns, :count, count)

    ~H"""
    <div class="mb-8">
      <div class="mt-0.5 text-title6 font-title6 leading-snug text-grey1">
        <%= dgettext("eyra-assignment", "settings.subject_count.label") %>
      </div>
      <.spacing value="XXS" />
      <div class="text-label font-label text-grey2 mb-3">
        <%= dgettext("eyra-assignment", "settings.subject_count.tooltip") %>
      </div>
      <div class="text-title3 font-light text-grey1">
        <%= @count %>
      </div>
    </div>
    """
  end

  defp show_language_field?(content_flags) do
    Map.get(content_flags, :language, false)
  end

  defp render_language_field(assigns) do
    ~H"""
    <.language_selector
      form={@form}
      field={:language}
      items={@language_items}
      mode={@language_mode} />
    """
  end

  defp language_selector(%{mode: :fixed_nl, items: items} = assigns) do
    items =
      Enum.map(items, fn item ->
        if item.id == "nl" or item.id == :nl do
          item
        else
          Map.put(item, :disabled, true)
        end
      end)

    assigns = Map.put(assigns, :items, items)

    ~H"""
    <.radio_group
      form={@form}
      field={@field}
      label_text={dgettext("eyra-assignment", "settings.language.label")}
      items={@items}
      label_subtitle={dgettext("eyra-assignment", "settings.language.fixed_nl_message")}
    />
    """
  end

  defp language_selector(%{mode: :free_choice} = assigns) do
    ~H"""
    <.radio_group
      form={@form}
      field={@field}
      label_text={dgettext("eyra-assignment", "settings.language.label")}
      items={@items}
    />
    """
  end
end
