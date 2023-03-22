defmodule Systems.Org.NodeContentView do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text.{Title2, Title3}
  alias Frameworks.Pixel.Form.{Form, TextInput, Dropdown}

  alias Systems.{
    Org,
    Content
  }

  prop(props, :map)

  data(changeset, :any)
  data(options, :list)
  data(selected_option, :atom)

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
  def update(%{id: id, props: %{node: entity, locale: _locale}}, socket) do
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

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <Title2>{dgettext("eyra-org", "node.title")}</Title2>
      <Form id="node_form" changeset={@changeset} change_event="save" target={@myself}>
        <TextInput field={:identifier_string} label_text={dgettext("eyra-org", "identifier.label")} />
        <Spacing value="XS" />

        <TextInput field={:domains_string} label_text={dgettext("eyra-org", "domains.label")} />
        <Spacing value="XS" />

        <Dropdown
          field={:type_string}
          options={@options}
          selected_option={@selected_option}
          label_text={dgettext("eyra-org", "type.selector.label")}
          target={@myself}
        />
        <Spacing value="L" />

        <Title3>{dgettext("eyra-org", "full.name.title")}</Title3>
        <Content.TextBundleInputs field={:full_name_bundle} target={@myself} />
        <Spacing value="M" />

        <Title3>{dgettext("eyra-org", "short.name.title")}</Title3>
        <Content.TextBundleInputs field={:short_name_bundle} target={@myself} />
      </Form>
    </ContentArea>
    """
  end
end
