defmodule CoreWeb.User.Forms.Scholar do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.Features

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title2, BodyMedium}

  alias Systems.{
    Scholar,
    Content
  }

  prop(props, :any, required: true)

  data(user, :any)
  data(entity, :any)
  data(scholar_classes, :any)
  data(scholar_class_labels, :any)

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

    scholar_classes =
      Scholar.Context.list_classes([":2021"],
        short_name_bundle: Content.TextBundleModel.preload_graph(:full)
      )

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(scholar_classes: scholar_classes)
      |> update_ui()
    }
  end

  defp update_ui(socket) do
    update_scholar_classes(socket)
  end

  defp update_scholar_classes(
         %{
           assigns: %{
             scholar_classes: scholar_classes,
             user: user
           }
         } = socket
       ) do
    active_classes = Scholar.Context.list_classes(user)

    active_codes =
      scholar_classes
      |> Enum.filter(&active?(&1, active_classes))
      |> Enum.map(&Scholar.Class.code(&1.identifier))

    locale = Gettext.get_locale(CoreWeb.Gettext)
    scholar_class_labels = Scholar.Class.selector_labels(scholar_classes, locale, active_codes)

    socket
    |> assign(scholar_class_labels: scholar_class_labels)
  end

  defp active?(%{id: class_id}, [_ | _] = active_classes) do
    Enum.find(active_classes, &(&1.id == class_id)) != nil
  end

  defp active?(_, _), do: false

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
        <Title2>{dgettext("eyra-ui", "tabbar.item.scholar")}</Title2>
        <BodyMedium>{dgettext("eyra-account", "feature.study.description")}</BodyMedium>
        <Spacing value="S" />
        <Selector
          grid_options="grid grid-cols-2 gap-y-3"
          id={:study_program_codes}
          items={@scholar_class_labels}
          type={:checkbox}
          parent={%{type: __MODULE__, id: @id}}
        />
      </FormArea>
    </ContentArea>
    """
  end
end
