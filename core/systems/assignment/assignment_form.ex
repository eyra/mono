defmodule Systems.Assignment.AssignmentForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Assignment
  }

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity: %{id: entity_id, assignable_experiment: experiment} = entity,
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
        user: user,
        callback_url: callback_url
      )
    }
  end

  defp forms(%{
         tool_form: tool_form,
         tool_id: tool_id,
         experiment: experiment,
         callback_url: callback_url,
         user: user
       }) do
    [
      %{
        live_component: Assignment.ExperimentForm,
        props: %{
          id: :experiment_form,
          entity: experiment
        }
      },
      %{
        live_component: tool_form,
        props: %{
          id: :tool_form,
          entity_id: tool_id,
          callback_url: callback_url,
          user: user
        }
      },
      %{
        live_component: Assignment.EthicalForm,
        props: %{
          id: :ethical_form,
          entity: experiment
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
