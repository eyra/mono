defmodule CoreWeb.User.Forms.Study do
  use CoreWeb.LiveForm

  alias Core.Enums.StudyProgramCodes
  alias Core.Accounts
  alias Core.Accounts.Features

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title2, BodyMedium}

  prop(props, :any, required: true)

  data(user, :any)
  data(entity, :any)
  data(study_labels, :any)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, :auto_save, %{selector_id => active_item_ids})}
  end

  def update(%{id: id, props: %{user: user}}, socket) do
    entity = Accounts.get_features(user)

    study_labels = StudyProgramCodes.labels(entity.study_program_codes)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(study_labels: study_labels)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    study_labels = StudyProgramCodes.labels(entity.study_program_codes)

    socket
    |> assign(study_labels: study_labels)
  end

  def save(socket, %Core.Accounts.Features{} = entity, type, attrs) do
    changeset = Features.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <FormArea>
        <Title2>{dgettext("eyra-ui", "tabbar.item.study")}</Title2>
        <BodyMedium>{dgettext("eyra-account", "feature.study.description")}</BodyMedium>
        <Spacing value="S" />
        <Selector
          grid_options="grid grid-cols-2 gap-y-3"
          id={:study_program_codes}
          items={@study_labels}
          type={:checkbox}
          parent={%{type: __MODULE__, id: @id}}
        />
      </FormArea>
    </ContentArea>
    """
  end
end
