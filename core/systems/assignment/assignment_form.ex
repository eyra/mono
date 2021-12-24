defmodule Systems.Assignment.AssignmentForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text.Title2

  alias Systems.{
    Assignment
  }

  prop props, :map

  data entity_id, :number
  data callback_url, :string
  data validate?, :boolean
  data experiment_id, :number
  data tool_id, :number
  data tool_form, :number

  def update(%{claim_focus: form}, %{assigns: assigns} = socket) do
    assigns
    |> forms()
    |> filter(form)
    |> Enum.each(fn %{component: component, props: %{id: id}} ->
      IO.puts("send_update #{component}, #{id}, focus: ''")
      send_update(component, id: id, focus: "")
    end)

    {:ok, socket}
  end

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
      when new != current do

    IO.puts("UPDATE Y")

    {
      :ok,
      socket
      |> assign(validate?: new)
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    IO.puts("UPDATE DRAIN")
    {:ok, socket}
  end

  # Handle initial update
  def update(
        %{id: id, props: %{entity_id: entity_id, validate?: validate?, uri_origin: uri_origin}},
        socket
      ) do

    preload = Assignment.Model.preload_graph(:full)
    %{assignable_experiment: experiment} = Assignment.Context.get!(entity_id, preload)

    callback_path = CoreWeb.Router.Helpers.live_path(socket, Systems.Assignment.CallbackPage, entity_id)
    callback_url = uri_origin <> callback_path

    tool_id = Assignment.ExperimentModel.tool_id(experiment)
    tool_form = Assignment.ExperimentModel.tool_form(experiment)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(experiment_id: experiment.id)
      |> assign(callback_url: callback_url)
      |> assign(tool_id: tool_id)
      |> assign(tool_form: tool_form)
      |> assign(validate?: validate?)
    }
  end

  @impl true
  def handle_event("reset_focus", _, socket) do

    {:noreply, socket |> assign(focus: "")}
  end

  defp forms(%{
    tool_form: tool_form,
    tool_id: tool_id,
    experiment_id: experiment_id,
    validate?: validate?,
    callback_url: callback_url
  }) do
    [
      %{
        component: Assignment.ExperimentForm,
        props: %{id: :experiment_form, entity_id: experiment_id, validate?: validate?}
      },
      %{
        component: tool_form,
        props: %{id: :tool_form, entity_id: tool_id, validate?: validate?, callback_url: callback_url}
      },
      %{
        component: Assignment.EthicalForm,
        props: %{id: :ethical_form, entity_id: experiment_id, validate?: validate?}
      }
    ]
  end

  defp filter(forms, exclude_form_id) do
    Enum.filter(forms, &(&1.props.id != exclude_form_id))
  end

  def render(assigns) do
    ~F"""
      <ContentArea class="mb-4">
        <MarginY id={:page_top} />
        <Title2>{dgettext("eyra-assignment", "form.title")}</Title2>
        <Spacing value="M" />

        <div class="flex flex-col gap-12 lg:gap-16">
          <Dynamic :for={form <- forms(assigns)} component={form.component} props={form.props} />
        </div>
      </ContentArea>
    """
  end
end
