defmodule Systems.Assignment.AssignmentForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Assignment
  }

  # Handle update from parent
  @impl true
  def update(
        %{validate?: validate?, active_field: active_field},
        %{assigns: %{entity: _}} = socket
      ) do
    {
      :ok,
      socket
      |> update_validate?(validate?)
      |> update_active_field(active_field)
    }
  end

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity: %{id: entity_id, assignable_experiment: experiment} = entity,
          validate?: validate?,
          active_field: active_field,
          user: user,
          uri_origin: uri_origin
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
        active_field: active_field,
        user: user,
        callback_url: callback_url
      )
    }
  end

  defp update_active_field(%{assigns: %{active_field: current}} = socket, new)
       when new != current do
    socket
    |> assign(active_field: new)
  end

  defp update_active_field(socket, _new), do: socket

  defp update_validate?(%{assigns: %{validate?: current}} = socket, new) when new != current do
    socket
    |> assign(validate?: new)
  end

  defp update_validate?(socket, _new), do: socket

  defp forms(%{
         tool_form: tool_form,
         tool_id: tool_id,
         experiment: experiment,
         validate?: validate?,
         active_field: active_field,
         callback_url: callback_url,
         user: user
       }) do
    [
      %{
        live_component: Assignment.ExperimentForm,
        props: %{
          id: :experiment_form,
          entity: experiment,
          validate?: validate?,
          active_field: active_field
        }
      },
      %{
        live_component: tool_form,
        props: %{
          id: :tool_form,
          entity_id: tool_id,
          validate?: validate?,
          active_field: active_field,
          callback_url: callback_url,
          user: user
        }
      },
      %{
        live_component: Assignment.EthicalForm,
        props: %{
          id: :ethical_form,
          entity: experiment,
          validate?: validate?,
          active_field: active_field
        }
      }
    ]
  end

  defp forms(_), do: []

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content class="mb-4">
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "form.title") %></Text.title2>
        <.spacing value="M" />

        <div class="flex flex-col gap-12 lg:gap-16">
          <%= for form <- forms(assigns) do %>
            <.live_component module={form.live_component} {form.props} />
          <% end %>
        </div>
      </Area.content>
    </div>
    """
  end
end
