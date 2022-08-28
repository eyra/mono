defmodule Systems.Admin.ImportRewardsPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :import_rewards
  use CoreWeb.FileUploader, ~w(.csv)

  alias Surface.Components.Form

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Button.{BackButton, PrimaryLabelButton}

  alias Frameworks.Pixel.Container.{Wrap}
  alias Frameworks.Pixel.Text.{Title2, Title3, Title6, BodyLarge}
  alias Frameworks.Pixel.Form.{Form, TextInput}
  alias Frameworks.Pixel.Panel.Panel
  alias Frameworks.Pixel.Selector.Selector

  alias Systems.{
    Campaign,
    Admin,
    Scholar,
    Org
  }

  data(back_path, :any)
  data(process_button, :any)
  data(import_button, :any)
  data(entity, :any)
  data(changeset, :any)

  data(currency, :atom, default: :first)
  data(local_file, :any, default: nil)
  data(session_key, :string, default: "")
  data(uploaded_file, :string, default: "-")
  data(lines_error, :any)
  data(lines_unknown, :any)
  data(lines_valid, :any)
  data(focus, :any, default: "")

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_local_relative_path, local_full_path, remote_file}
      ) do
    changeset =
      entity |> Admin.ImportRewardsModel.changeset(%{session_key: Path.rootname(remote_file)})

    socket
    |> assign(
      changeset: changeset,
      lines_error: [],
      lines_unknown: [],
      lines_valid: [],
      local_file: local_full_path,
      uploaded_file: remote_file
    )
  end

  def filter_ok({:ok, _}), do: true
  def filter_ok(_), do: false

  def filter_valid(%{:status => :ready_to_import}), do: true
  def filter_valid(%{:status => :incorrect_currency}), do: true
  def filter_valid(%{:status => :transaction_exists}), do: true
  def filter_valid(_), do: false

  def filter_unknown(%{:status => :unknown}), do: true
  def filter_unknown(_), do: false

  def filter_error({:error, _}), do: true
  def filter_error(_), do: false

  def map({:ok, line}), do: line
  def map({:error, message}), do: message

  def validate(%{"email" => email, "student_id" => student_id} = line, socket) do
    if user = Core.SurfConext.get_user_by_student_id(student_id) do
      IO.puts("User found by student_id! #{user.id}")
      line |> validate(user, socket)
    else
      if user = Core.Accounts.get_user_by_email(email) do
        IO.puts("User found by email! #{user.id}")
        line |> validate(user, socket)
      else
        line |> Map.put(:status, :unknown)
      end
    end
  end

  def validate(
        %{"credits" => credits} = line,
        user,
        %{assigns: %{session_key: session_key, currency: currency}} = _socket
      ) do
    {status, message} =
      if Campaign.Context.user_has_currency?(user, currency) do
        if transaction_exists?(user, session_key) do
          {:transaction_exists, "Import done"}
        else
          credits = String.to_integer(credits)

          if credits <= 0 do
            {:zero_credits, "Zero credits"}
          else
            {:ready_to_import, ""}
          end
        end
      else
        {:incorrect_currency, "Student is not part of #{currency}"}
      end

    line
    |> Map.put(:status, status)
    |> Map.put(:message, message)
    |> Map.put(:user_id, user.id)
  end

  defp transaction_exists?(user, session_key) do
    Campaign.Context.import_student_reward_exists?(user.id, session_key)
  end

  defp process(%{assigns: %{local_file: local_file}} = socket) do
    lines =
      local_file
      |> File.stream!()
      |> CSV.decode(headers: true)

    lines_error =
      lines
      |> Enum.filter(&filter_error(&1))
      |> Enum.map(&map(&1))

    lines_ok =
      lines
      |> Enum.filter(&filter_ok(&1))
      |> Enum.map(&map(&1))
      |> Enum.map(&validate(&1, socket))

    lines_valid =
      lines_ok
      |> Enum.filter(&filter_valid(&1))

    lines_unknown =
      lines_ok
      |> Enum.filter(&filter_unknown(&1))

    socket
    |> assign(
      lines_error: lines_error,
      lines_unknown: lines_unknown,
      lines_valid: lines_valid
    )
  end

  defp import_all(%{assigns: %{lines_valid: lines_valid}} = socket) do
    lines_valid
    |> Enum.filter(&(&1.status == :ready_to_import))
    |> Enum.each(&import_single(socket, &1))

    socket
    |> process()
  end

  defp import_single(%{assigns: %{lines_valid: lines_valid}} = socket, index)
       when is_integer(index) do
    line = lines_valid |> Enum.at(index)

    socket
    |> import_single(line)
    |> process()
  end

  defp import_single(
         %{assigns: %{session_key: session_key, currency: currency}} = socket,
         %{:user_id => user_id, "credits" => credits} = _line
       ) do
    credits = String.to_integer(credits)
    Campaign.Context.import_student_reward(user_id, credits, session_key, currency)

    socket
  end

  def handle_info(%{active_item_id: currency, selector_id: :currency}, socket) do
    {:noreply, socket |> assign(currency: currency)}
  end

  @impl true
  def handle_event("import_all", _params, socket) do
    {
      :noreply,
      socket
      |> import_all()
    }
  end

  @impl true
  def handle_event("import_single", %{"item" => index} = _params, socket) do
    {
      :noreply,
      socket
      |> import_single(index |> String.to_integer())
    }
  end

  @impl true
  def handle_event("process", _params, %{assigns: %{changeset: changeset}} = socket) do
    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, entity} ->
          socket
          |> assign(entity: entity, session_key: entity.session_key)
          |> process()

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset, focus: "")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change",
        %{"import_rewards_model" => %{"session_key" => session_key}},
        %{assigns: %{entity: entity}} = socket
      ) do
    changeset = entity |> Admin.ImportRewardsModel.changeset(%{session_key: session_key})

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, entity} ->
          socket |> assign(changeset: changeset, entity: entity)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset, focus: "")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("focus", %{"field" => field}, socket) do
    {
      :noreply,
      socket
      |> assign(focus: field)
    }
  end

  def mount(%{"back" => back}, _session, socket) do
    entity = %Admin.ImportRewardsModel{}

    changeset =
      entity
      |> Admin.ImportRewardsModel.changeset(%{})

    process_button = %{
      action: %{
        type: :send,
        event: "process"
      },
      face: %{
        type: :secondary,
        border_color: "bg-tertiary",
        text_color: "text-tertiary",
        label: "Start session"
      }
    }

    import_button = %{
      action: %{
        type: :send,
        event: "import_all"
      },
      face: %{
        type: :primary,
        label: "Import all"
      }
    }

    currency_labels =
      Org.Context.list_nodes(:scholar_course, ["vu", ":2021"])
      |> Enum.map(&Scholar.Course.currency(&1.identifier))
      |> Enum.map(&%{id: &1, value: &1, active: false})

    {
      :ok,
      socket
      |> assign(
        local_file: nil,
        entity: entity,
        changeset: changeset,
        process_button: process_button,
        import_button: import_button,
        currency_labels: currency_labels,
        back_path: back,
        lines_valid: [],
        lines_unknown: [],
        lines_error: []
      )
      |> init_file_uploader(:csv)
    }
  end

  defp message_color(%{status: :incorrect_currency}), do: "text-delete"
  defp message_color(%{status: :transaction_exists}), do: "text-grey1"
  defp message_color(%{status: :zero_credits}), do: "text-warning"
  defp message_color(_), do: "text-grey1"

  defp opacity(%{status: :transaction_exists}), do: "opacity-30"
  defp opacity(_), do: "opacity-100"

  def render(assigns) do
    ~F"""
    <Workspace title="Import rewards" menus={@menus}>
      <MarginY id={:page_top} />
      <ContentArea>
        <Panel bg_color="bg-grey1">
          <Form id="import_form" changeset={@changeset} change_event="change" focus={@focus} target="">
            <Title3 color="text-white">Setup the import session</Title3>
            <Spacing value="XXS" />
            <BodyLarge color="text-white">Selected file: <span class="text-tertiary">{@uploaded_file}</span></BodyLarge>
            <Spacing value="S" />
            <div class="flex flex-row gap-4">
              <div class="flex-wrap">
                <PrimaryLabelButton
                  label="Select csv file"
                  field={@uploads.csv.ref}
                  bg_color="bg-tertiary"
                  text_color="text-grey1"
                />
                {live_file_input(@uploads.csv, class: "hidden")}
              </div>
            </div>
            <div :if={@local_file} class="flex-wrap">
              <Spacing value="M" />
              <TextInput
                field={:session_key}
                label_text="Session key"
                background={:dark}
                label_color="text-white"
              />
              <Spacing value="XS" />
              <Title6 color="text-white">Currency</Title6>
              <Spacing value="XS" />
              <Selector
                id={:currency}
                items={@currency_labels}
                type={:radio}
                parent={self()}
                background={:dark}
              />
              <Spacing value="L" />
              <Wrap>
                <DynamicButton vm={@process_button} />
              </Wrap>
            </div>
          </Form>
        </Panel>
        <Spacing value="L" />
        <div :if={@lines_valid |> Enum.count() > 0}>
          <Spacing value="XL" />
          <Title2 margin="mb-0">Credit transactions</Title2>
          <Spacing value="S" />
          <Panel>
            <table>
              <tr>
                <td class="pr-4"><BodyLarge>Session key</BodyLarge></td>
                <td><BodyLarge><span class="text-primary font-button">{@session_key}</span></BodyLarge></td>
              </tr>
              <tr>
                <td class="pr-4"><BodyLarge>Study year</BodyLarge></td>
                <td><BodyLarge><span class="text-primary font-button">{@currency}</span></BodyLarge></td>
              </tr>
            </table>
          </Panel>
          <Spacing value="L" />
          <table class="table-fixed">
            <thead>
              <tr class="text-left">
                <th class="pl-0 pr-8"><Title6>Email</Title6></th>
                <th class="pl-0 pr-8"><Title6>Student ID</Title6></th>
                <th class="pl-0 pr-8"><Title6>Credits</Title6></th>
                <th class="pl-0" />
              </tr>
            </thead>
            <tbody>
              <tr :for={{line, index} <- Enum.with_index(@lines_valid)} class={"#{opacity(line)} h-10"}>
                <td class="pr-8"><BodyLarge>{line["email"]}</BodyLarge></td>
                <td class="pr-8"><BodyLarge>{line["student_id"]}</BodyLarge></td>
                <td class="pr-8"><BodyLarge>{line["credits"]}</BodyLarge></td>
                <td class="pr-8">
                  <DynamicButton
                    :if={line.status == :ready_to_import}
                    vm={%{
                      action: %{type: :send, event: "import_single", item: index},
                      face: %{type: :icon, icon: :add}
                    }}
                  />
                  <BodyLarge color={message_color(line)}>{line.message}</BodyLarge>
                </td>
              </tr>
            </tbody>
          </table>
          <Spacing value="L" />
          <Wrap>
            <DynamicButton vm={@import_button} />
          </Wrap>
          <Spacing value="L" />
        </div>
        <div :if={@lines_error |> Enum.count() > 0}>
          <Title3>Parsing errors</Title3>
          <BodyLarge :for={message <- @lines_error}>{message}</BodyLarge>
          <Spacing value="M" />
        </div>
        <Spacing value="M" />
        <div :if={@lines_unknown |> Enum.count() > 0}>
          <Title3>Unknown students</Title3>
          <BodyLarge :for={line <- @lines_unknown}>{line["email"]}</BodyLarge>
          <Spacing value="M" />
        </div>
        <BackButton label="Back" path={@back_path} />
      </ContentArea>
    </Workspace>
    """
  end
end
