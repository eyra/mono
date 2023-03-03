defmodule Systems.Assignment.AssignmentForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text.Title2

  alias Systems.{
    Assignment
  }

  prop(props, :map)

  data(entity, :map)
  data(callback_url, :string)
  data(validate?, :boolean)
  data(experiment, :map)
  data(tool_id, :number)
  data(tool_form, :number)
  data(user, :map)

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
      when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
    }
  end

  # Handle initial update
  def update(
        %{
          id: id,
          props: %{
            entity: %{id: entity_id, assignable_experiment: experiment} = entity,
            validate?: validate?,
            user: user,
            uri_origin: uri_origin
          }
        },
        socket
      ) do
    callback_path =
      CoreWeb.Router.Helpers.live_path(socket, Systems.Assignment.CallbackPage, entity_id)

    callback_url = uri_origin <> callback_path

    tool_id = Assignment.ExperimentModel.tool_id(experiment)
    tool_form = Assignment.ExperimentModel.tool_form(experiment)

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        experiment: experiment,
        tool_id: tool_id,
        tool_form: tool_form,
        validate?: validate?,
        user: user,
        callback_url: callback_url
      )
    }
  end

  defp forms(%{
         tool_form: tool_form,
         tool_id: tool_id,
         experiment: experiment,
         validate?: validate?,
         callback_url: callback_url,
         user: user
       }) do
    [
      %{
        component: Assignment.ExperimentForm,
        props: %{
          id: :experiment_form,
          entity: experiment,
          validate?: validate?
        }
      },
      %{
        component: tool_form,
        props: %{
          id: :tool_form,
          entity_id: tool_id,
          validate?: validate?,
          callback_url: callback_url,
          user: user
        }
      },
      %{
        component: Assignment.EthicalForm,
        props: %{
          id: :ethical_form,
          entity: experiment,
          validate?: validate?
        }
      }
    ]
  end

  defp forms(_), do: []

  def render(assigns) do
    ~F"""
    <ContentArea class="mb-4">
      <MarginY id={:page_top} />
      <Title2>{dgettext("eyra-assignment", "form.title")}</Title2>
      <Spacing value="M" />

      <div class="flex flex-col gap-12 lg:gap-16">
        {#for form <- forms(assigns)}
          <Dynamic.LiveComponent module={form.component} {...form.props} />
        {/for}
      </div>
    </ContentArea>
    """
  end
end
