defmodule Systems.Student.Pool.SubmissionForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.Title3

  alias Systems.{
    Pool,
    Student
  }

  prop(entity, :map, required: true)
  prop(user, :map, required: true)

  data(criteria, :any)
  data(pool, :any)
  data(pool_labels, :any)
  data(changeset, :any)

  # Handle Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: :pools},
        %{assigns: %{pool_labels: pool_labels, submission: submission}} = socket
      ) do
    pool_id =
      case Enum.find(pool_labels, &(&1.id == active_item_id)) do
        %{id: pool_id} -> pool_id
        nil -> raise "Selector returned unavailable pool id"
      end

    {
      :ok,
      socket
      |> save(submission, pool_id)
    }
  end

  def update(
        %{id: id, entity: %{pool: active_pool} = submission, user: user},
        socket
      ) do
    pool_labels =
      Student.Public.course_patterns(user)
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
    }
  end

  # Saving
  def save(socket, %Pool.SubmissionModel{} = entity, pool_id) do
    changeset = Pool.SubmissionModel.changeset(entity, pool_id)

    socket
    |> save(changeset)
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <Title3 margin="mb-5 sm:mb-8">{dgettext("link-studentpool", "submission.selector.title")}</Title3>
      <Selector
        id={:pools}
        items={@pool_labels}
        type={:radio}
        parent={%{type: __MODULE__, id: @id}}
        optional?={false}
      />
      <Spacing value="L" />
    </ContentArea>
    """
  end
end
