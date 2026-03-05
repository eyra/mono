defmodule Systems.Student.Pool.SubmissionForm do
  @moduledoc false
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Systems.Pool
  alias Systems.Student

  @impl true
  def update(%{id: id, entity: %{pool: active_pool} = submission, user: user}, socket) do
    pool_labels =
      user
      |> Student.Public.course_patterns()
      |> Student.Public.list_courses()
      |> Enum.map(&Student.Course.pool_name(&1))
      |> Enum.map(&Pool.Public.get_by_name(&1, Pool.Model.preload_graph([:org])))
      |> Pool.Model.labels(active_pool)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(
        submission: submission,
        pool_labels: pool_labels
      )
      |> compose_child(:pools)
    }
  end

  @impl true
  def compose(:pools, %{pool_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio,
        optional?: false
      }
    }
  end

  # Saving
  def save(socket, %Pool.SubmissionModel{} = entity, pool_id) do
    changeset = Pool.SubmissionModel.changeset(entity, pool_id)

    save(socket, changeset)
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, source: %{name: :pools}},
        %{assigns: %{pool_labels: pool_labels, submission: submission}} = socket
      ) do
    pool_id =
      case Enum.find(pool_labels, &(&1.id == active_item_id)) do
        %{id: pool_id} -> pool_id
        nil -> raise "Selector returned unavailable pool id"
      end

    {
      :noreply,
      save(socket, submission, pool_id)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Text.title3 margin="mb-5 sm:mb-8"><%= dgettext("link-studentpool", "submission.selector.title") %></Text.title3>
       <.child name={:pools} fabric={@fabric} />
      <.spacing value="L" />
      </Area.content>
    </div>
    """
  end
end
