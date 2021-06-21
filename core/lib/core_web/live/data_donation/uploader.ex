defmodule CoreWeb.DataDonation.Uploader do
  use CoreWeb, :live_view

  alias Core.DataDonation.{Tools, Tool}

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Text.{Title3, BodyMedium, BodyLarge}
  alias EyraUI.Spacing
  alias EyraUI.Panel.Panel
  alias EyraUI.Container.{ContentArea, Bar, BarItem}

  defmodule UploadChangeset do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:terms_accepted, :boolean)
    end

    def changeset(params) do
      %UploadChangeset{}
      |> cast(params, [:terms_accepted])
      |> validate_required([:terms_accepted])
    end
  end

  data(result, :any)
  data(tool, :any)
  data(user, :any)
  data(ready, :boolean, default: false)

  def mount(%{"id" => tool_id}, _session, socket) do
    tool = Tools.get!(tool_id)

    {:ok,
     socket
     |> assign(:result, nil)
     |> assign(:tool, tool)
     |> assign(:changeset, UploadChangeset.changeset(%{}))}
  end

  @impl true
  def handle_event("script-initialized", _params, socket) do
    {:noreply, socket |> assign(:ready, true)}
  end

  def handle_event(
        "script-result",
        %{"data" => data},
        %{assigns: %{tool: tool, current_user: user}} = socket
      ) do
    Tool.store_results(tool, user, data)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <HeroSmall title={{ dgettext("eyra-data-donation", "uploader.title") }} />
    <ContentArea>
      <div id="controls" phx-hook="PythonUploader">
        <div :if={{not @ready}} id="loading-indicator" class="text-bodylarge font-body">
          We maken de pagina klaar om te doneren. Een moment geduld...
          <Spacing value="L" />
        </div>

        <Title3>Step 1: Download from Google</Title3>
        <BodyLarge>Bla bla bla bla https://takeout.google.com/u/2/?pli=1</BodyLarge>
        <Spacing value="L" />

        <Title3>Step 2: Select the downloaded data package</Title3>
        <BodyLarge>Bla bla bla bla</BodyLarge>
        <Spacing value="S" />

        <div :if={{@ready}}>
          <div>
            <label for="file-upload" class="inline-block pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 bg-primary cursor-pointer">
              Select file
            </label>
            <input id="file-upload" type="file" hidden/>
          </div>
        </div>
        <Spacing value="L" />

        <Title3>Step 3: Extract data</Title3>
        <BodyLarge>Bla bla bla bla</BodyLarge>
        <Spacing value="S" />
        <div :if={{@ready}}>
          <button class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 border-primary text-primary" data-role="process-trigger">
            Process selected file
          </button>
        </div>

        <div class="results" hidden>
          <Spacing value="L" />
          <Title3>Step 4: Donate results</Title3>
          <BodyLarge>This is extracted from your Google data</BodyLarge>
          <Spacing value="S" />
          <Panel bg_color="bg-grey5">
            <template slot="title">
            </template>
            <p class="summary" />
            <p class="extracted" />
          </Panel>
          <button class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 border-primary text-primary" data-role="share-trigger">
            Donate
          </button>
          <Spacing value="S" />
        </div>
        <Spacing value="L" />

        <Panel bg_color="bg-grey1">
          <Title3 color="text-white">Script</Title3>
          <BodyLarge color="text-white" >Dit script wordt gebruikt om data uit jou package te halen</BodyLarge>
          <Spacing value="L" />
          <template slot="title">
          </template>
          <div class="text-white">
            <pre><code>{{ @tool.script }}</code></pre>
          </div>
        </Panel>
      </div>
    </ContentArea>
    """
  end
end
