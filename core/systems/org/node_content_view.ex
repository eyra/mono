defmodule Systems.Org.NodeContentView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form

  alias Systems.{
    Org,
    Content
  }

  import Content.TextBundleInput

  # Successive update

  @impl true
  def update(_, %{assigns: %{node: _node}} = socket) do
    {
      :ok,
      socket
    }
  end

  # Initial update

  @impl true
  def update(%{id: id, node: entity, locale: _locale}, socket) do
    changeset = Org.NodeModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset
      )
      |> update_dropdown()
    }
  end

  defp update_dropdown(%{assigns: %{entity: %{type: type}}} = socket) do
    all_types = Org.Types.labels()
    options = all_types |> Enum.map(&to_option(&1))

    socket
    |> assign(
      options: options,
      selected_option: type
    )
  end

  defp to_option(%{id: id, value: value}), do: %{id: id, label: value}

  @impl true
  def handle_event(
        "select-option",
        %{"id" => type, "label" => type_string},
        %{assigns: %{entity: entity}} = socket
      ) do
    type = String.to_atom(type)

    {
      :noreply,
      socket
      |> save(entity, %{type: type, type_string: type_string})
      |> update_dropdown()
    }
  end

  @impl true
  def handle_event("save", %{"node_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  defp save(socket, entity, attrs) do
    changeset = Org.NodeModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-org", "node.title") %></Text.title2>
      <.form id="node_form" :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.text_input form={form} field={:identifier_string} label_text={dgettext("eyra-org", "identifier.label")} />
        <.spacing value="XS" />

        <.text_input form={form} field={:domains_string} label_text={dgettext("eyra-org", "domains.label")} />
        <.spacing value="XS" />

        <.dropdown
          form={form}
          field={:type_string}
          options={@options}
          selected_option={@selected_option}
          label_text={dgettext("eyra-org", "type.selector.label")}
          target={@myself}
        />
        <.spacing value="L" />

        <Text.title3><%= dgettext("eyra-org", "full.name.title") %></Text.title3>
        <.text_bundle_input form={form} field={:full_name_bundle} target={@myself} />
        <.spacing value="M" />

        <Text.title3><%= dgettext("eyra-org", "short.name.title") %></Text.title3>
        <.text_bundle_input form={form} field={:short_name_bundle} target={@myself} />
      </.form>
      </Area.content>
    </div>
    """
  end
end
