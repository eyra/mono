defmodule CoreWeb.User.Forms.Scholar do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.Features

  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title2, Title4, BodyMedium}

  alias Systems.{
    Scholar,
    Budget,
    Content
  }

  prop(props, :any, required: true)

  data(user, :any)
  data(entity, :any)
  data(title, :any)
  data(scholar_classes, :any)
  data(scholar_class_labels, :any)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    active_item_ids =
      active_item_ids
      |> Enum.map(&String.to_atom(&1))

    {:ok, socket |> save(entity, :auto_save, %{selector_id => active_item_ids})}
  end

  def update(%{id: id, props: %{user: user}}, socket) do
    entity = Accounts.get_features(user)

    current_year = Scholar.Context.academic_year()
    last_year = current_year - 1

    wallets_last_year_finised =
      user
      |> Budget.Context.list_wallets()
      |> Enum.filter(
        &(is_year?(&1, last_year) and
            finished?(&1))
      )

    classes =
      classes(current_year)
      |> Enum.filter(&(not member?(wallets_last_year_finised, &1, current_year)))

    title = "VU SBE #{Scholar.Context.academic_year()}"

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(scholar_classes: classes)
      |> assign(title: title)
      |> update_ui()
    }
  end

  defp member?([_ | _] = finished_wallets, class, current_year) do
    course = Scholar.Class.get_course(class)

    finished_wallets
    |> Enum.map(&Scholar.Course.get_by_wallet(&1))
    |> Enum.find(&successor?(&1, course, current_year)) != nil
  end

  defp successor?(
         %{identifier: finished_currency} = _finished_course,
         %{identifier: currency} = _course,
         current_year
       ) do
    Scholar.Context.successor?(finished_currency, currency, current_year)
  end

  defp finished?(%{balance_credit: balance_credit} = wallet) do
    balance_credit >= Scholar.Context.get_target(wallet)
  end

  defp is_year?(%{identifier: identifier}, year), do: is_year?(identifier, year)

  defp is_year?(["wallet", currency_name, _], year),
    do: String.ends_with?(currency_name, "_#{year}")

  defp classes(academic_year) do
    Scholar.Context.list_classes([":#{academic_year}"], [
      :links,
      short_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ])
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
        <Spacing value="M" />
        <Title4>{@title}</Title4>
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
