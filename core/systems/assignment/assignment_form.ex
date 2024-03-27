defmodule Systems.Assignment.AssignmentForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Assignment,
    Workflow
  }

  # Handle initial update
  @impl true
  def update(
        %{
          id: id,
          entity: %{info: info, workflow: workflow} = entity,
          user: user,
          uri_origin: uri_origin
        },
        socket
      ) do
    [tool | _] = Workflow.Model.flatten(workflow)
    tool_form = Frameworks.Concept.ToolModel.form(tool, nil)

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        info: info,
        tool: tool,
        tool_form: tool_form,
        user: user,
        uri_origin: uri_origin
      )
    }
  end

  defp forms(%{
         tool_form: tool_form,
         tool: tool,
         info: info,
         uri_origin: uri_origin,
         user: user
       }) do
    callback_path = ~p"/assignment/callback/#{tool.id}"
    callback_url = uri_origin <> callback_path

    [
      # %{
      #   live_component: Assignment.InfoForm,
      #   props: %{
      #     id: :info_form,
      #     entity: info
      #   }
      # },
      %{
        live_component: tool_form,
        props: %{
          id: :tool_form,
          entity: tool,
          callback_url: callback_url,
          user: user
        }
      },
      %{
        live_component: Assignment.EthicalForm,
        props: %{
          id: :ethical_form,
          entity: info
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
