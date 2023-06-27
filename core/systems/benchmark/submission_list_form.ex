defmodule Systems.Benchmark.SubmissionListForm do
  use CoreWeb, :live_component

  alias Frameworks.Utility.ViewModelBuilder

  alias Systems.{
    Benchmark
  }

  @impl true
  def update(%{action: :close}, socket) do
    send(self(), {:hide_popup})

    {
      :ok,
      socket
      |> update_spot()
      |> update_vm()
    }
  end

  @impl true
  def update(%{id: id, spot_id: spot_id, active?: active?}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        spot_id: spot_id,
        active?: active?
      )
      |> update_spot()
      |> update_vm()
    }
  end

  defp update_spot(%{assigns: %{spot_id: spot_id}} = socket) do
    spot =
      Benchmark.Public.get_spot!(
        String.to_integer(spot_id),
        Benchmark.SpotModel.preload_graph(:down)
      )

    socket |> assign(spot: spot)
  end

  defp update_vm(%{assigns: %{spot: spot}} = socket) do
    vm = ViewModelBuilder.view_model(spot, __MODULE__, socket.assigns)
    socket |> assign(vm: vm)
  end

  @impl true
  def handle_event("add", _params, %{assigns: %{spot: spot, id: id}} = socket) do
    popup = %{
      id: :submission_form,
      module: Benchmark.SubmissionForm,
      spot: spot,
      submission: %Benchmark.SubmissionModel{},
      parent: %{type: __MODULE__, id: id}
    }

    send(self(), {:show_popup, popup})

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "edit",
        %{"item" => item_id},
        %{assigns: %{id: id, spot: %{submissions: submissions} = spot}} = socket
      ) do
    if submission = Enum.find(submissions, &(&1.id == String.to_integer(item_id))) do
      popup = %{
        id: :submission_form,
        module: Benchmark.SubmissionForm,
        spot: spot,
        submission: submission,
        parent: %{type: __MODULE__, id: id}
      }

      send(self(), {:show_popup, popup})
    end

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "remove",
        %{"item" => item_id},
        %{assigns: %{spot: %{submissions: submissions}}} = socket
      ) do
    if submission = Enum.find(submissions, &(&1.id == String.to_integer(item_id))) do
      Benchmark.Public.delete(submission)
    end

    {
      :noreply,
      socket
      |> update_spot()
      |> update_vm()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2><%= @vm.title %></Text.title2>
      <Text.intro margin="mb-4 lg:mb-6"><%= @vm.intro %></Text.intro>
      <Text.sub_head><%= @vm.subhead %></Text.sub_head>
      <.spacing value="M" />

      <Benchmark.SubmissionView.list items={@vm.items} />

      <%= if @vm.add_button do %>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic {@vm.add_button} />
        </.wrap>
      <% end %>
    </div>
    """
  end
end
