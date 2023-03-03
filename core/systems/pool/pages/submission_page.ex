defmodule Systems.Pool.SubmissionPage do
  @moduledoc """
   The submission page for a campaign.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_submission
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.ButtonBar
  alias CoreWeb.UI.Member
  alias CoreWeb.UI.Timestamp
  alias CoreWeb.UI.ContentList

  alias Frameworks.Pixel.Text.{Title1, Title3, SubHead}

  alias Systems.{
    Pool
  }

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    submission_id = String.to_integer(id)
    %{pool: %{director: director}} = Pool.Public.get_submission!(submission_id, [:pool])
    model = %{id: submission_id, director: director}

    {
      :ok,
      socket
      |> assign(
        model: model,
        changesets: %{},
        dialog: nil
      )
      |> observe_view_model()
      |> update_menus()
    }
  end

  defoverridable handle_uri: 1

  @impl true
  def handle_uri(%{assigns: %{uri_path: uri_path, vm: %{promotion_id: promotion_id}}} = socket) do
    preview_path =
      Routes.live_path(socket, Systems.Promotion.LandingPage, promotion_id,
        preview: true,
        back: uri_path
      )

    super(assign(socket, preview_path: preview_path))
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    IO.puts("handle_view_model_updated")
    socket |> update_menus()
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    {:noreply, socket |> update_menus()}
  end

  @impl true
  def handle_event("publish", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    socket =
      if ready_for_publish?(submission) do
        {:ok, _} =
          Pool.Public.update(submission, %{status: :accepted, accepted_at: Timestamp.naive_now()})

        title = dgettext("eyra-submission", "publish.success.title")
        text = dgettext("eyra-submission", "publish.success.text")

        socket
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "publish.error.title")
        text = dgettext("eyra-submission", "publish.error.text")

        socket
        |> inform(title, text)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("retract", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _} = Pool.Public.update(submission, %{status: :idle})

    title = dgettext("eyra-submission", "retract.admin.success.title")
    text = dgettext("eyra-submission", "retract.admin.success.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event("complete", _params, %{assigns: %{vm: %{submission: submission}}} = socket) do
    {:ok, _} =
      Pool.Public.update(submission, %{status: :completed, completed_at: Timestamp.naive_now()})

    title = dgettext("eyra-submission", "complete.admin.success.title")
    text = dgettext("eyra-submission", "complete.admin.success.text")

    {
      :noreply,
      socket
      |> assign(accepted?: false)
      |> inform(title, text)
    }
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  defp ready_for_publish?(submission) do
    changeset =
      Pool.SubmissionModel.operational_changeset(submission, %{})
      |> Pool.SubmissionModel.operational_validation()

    changeset.valid?
  end

  defp action_map(%{preview_path: preview_path}) do
    preview_action = %{type: :redirect, to: preview_path}
    publish_action = %{type: :send, event: "publish"}
    retract_action = %{type: :send, event: "retract"}
    complete_action = %{type: :send, event: "complete"}

    %{
      accept: %{
        action: publish_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "publish.button"),
          bg_color: "bg-success"
        }
      },
      preview: %{
        action: preview_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "preview.button"),
          bg_color: "bg-primary"
        }
      },
      retract: %{
        action: retract_action,
        face: %{type: :icon, icon: :retract, alt: dgettext("link-ui", "retract.button")}
      },
      complete: %{
        action: complete_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "complete.button"),
          text_color: "text-grey1",
          bg_color: "bg-tertiary"
        }
      }
    }
  end

  defp create_actions(%{vm: %{accepted?: accepted?, completed?: completed?}} = assigns) do
    create_actions(action_map(assigns), accepted?, completed?)
  end

  defp create_actions(%{accept: accept, preview: preview, complete: complete}, false, false),
    do: [preview, accept, complete]

  defp create_actions(%{accept: accept, preview: preview}, false, _), do: [preview, accept]
  defp create_actions(%{accept: accept, preview: preview}, _, true), do: [preview, accept]

  defp create_actions(%{preview: preview, retract: retract, complete: complete}, true, false),
    do: [preview, complete, retract]

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  @impl true
  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-studentpool", "submission.title")} menus={@menus}>
      <div
        :if={show_dialog?(@dialog)}
        class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog {...@dialog} />
        </div>
      </div>
      <div>
        <ContentArea>
          <MarginY id={:page_top} />
          <Member :if={@vm.member} vm={@vm.member} />
          <Spacing value="XL" />
          <Title1>{@vm.title}</Title1>
          <Spacing value="L" />
          <SubHead>{@vm.byline}</SubHead>
          <Spacing value="L" />
        </ContentArea>

        <Dynamic.LiveComponent
          id={:submission_pool_form}
          module={@vm.form.component}
          {...@vm.form.props}
        />

        <ContentArea :if={Enum.count(@vm.excluded_campaigns) > 0}>
          <Title3 margin="mb-5 sm:mb-8">{dgettext("link-studentpool", "excluded.campaigns.title")}</Title3>
          <ContentList items={@vm.excluded_campaigns} />
          <Spacing value="M" />
        </ContentArea>

        <Spacing value="S" />
        <Pool.SubmissionView
          id={:submission_form}
          props={%{entity: @vm.submission, validate?: @vm.validate?}}
        />
      </div>
      <ContentArea>
        <MarginY id={:button_bar_top} />
        <ButtonBar buttons={create_actions(assigns)} />
      </ContentArea>
    </Workspace>
    """
  end
end
