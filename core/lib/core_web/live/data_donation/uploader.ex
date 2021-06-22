defmodule CoreWeb.DataDonation.Uploader do
  use CoreWeb, :live_view

  alias Core.DataDonation.{Tools, Tool}

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Text.{Title3, Title4, BodyLarge, BodyMedium}
  alias EyraUI.Spacing
  alias EyraUI.Panel.Panel
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Button.LinkButton

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
  data(loading, :boolean, default: true)
  data(step2, :css_class, default: "hidden")
  data(step3, :css_class, default: "hidden")
  data(step4, :css_class, default: "hidden")
  data(summary, :any, default: "<b>AAP</b>")
  data(extracted, :any, default: "AAP")

  def mount(%{"id" => tool_id}, _session, socket) do
    tool = Tools.get!(tool_id)

    {:ok,
     socket
     |> assign(:result, nil)
     |> assign(:tool, tool)
     |> assign(:changeset, UploadChangeset.changeset(%{}))}
  end

  def handle_event(
        "donate",
        %{"data" => data},
        %{assigns: %{tool: tool, current_user: user}} = socket
      ) do
    Tool.store_results(tool, user, data)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  def render(assigns) do
    ~H"""
    <HeroSmall title={{ dgettext("eyra-data-donation", "uploader.title") }} />
    <ContentArea>
      <div id="controls" phx-hook="PythonUploader">
        <Title3>Step 1: Download from Google</Title3>
        <BodyLarge>Go to the
        <a href= "https://takeout.google.com/u/2/?pli=1" class="text-bodylarge font-body text-primary hover:text-grey1 underline focus:outline-none" >
          Google Takeout page
        </a>
        and follow the indicated steps to download your Google data package.
        </BodyLarge>

        <div class="loading-indicator text-bodymedium font-body text-grey2">
        <Spacing value="L" />
        We are preparing the page for donation. One moment please...
        </div>

        <div class="step2" hidden>
          <Spacing value="XL" />
          <Title3>Step 2: Select the downloaded data package</Title3>
          <BodyLarge>Once you have received your data package from Google and stored it on your device,
          <label for="file-upload" class="text-bodylarge font-body text-primary hover:text-grey1 underline focus:outline-none cursor-pointer">
            select the file location
          </label>
          <input id="file-upload" type="file" data-role="file-input" hidden/>
          of the package.
          </BodyLarge>
          <Spacing value="S" />
          <BodyMedium><b>Note:</b> your data package stays at your device and will not be uploaded to a server.</BodyMedium>
          <Spacing value="S" />
        </div>

        <div class="step3" hidden>
          <Spacing value="XL" />
          <Title3>Step 3: Extract data</Title3>
          <BodyLarge>By clicking the button below, the data that is relevant for this research, will be extracted from your data package. During this process the data package will not leave your device and no data is stored on a server. The extracted data will be shown at step 4 for your consent. For your reference, the script that is used to extract the relevant data from your data package, is shown at the bottom of this page.</BodyLarge>
          <Spacing value="S" />
          <div>
            <button class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 bg-primary" data-role="process-trigger">
              Process data package
            </button>
          </div>
        </div>

        <div class="step4" hidden>
          <Spacing value="XL" />
          <Title3>Step 4: Donate extracted data</Title3>
          <BodyLarge>The data that was extracted from your data package is shown below. Make sure, you check this data carefully before pressing the donate button below. If you have checked the extracted data and consent with donating this data for research, press the donate button.</BodyLarge>
          <Spacing value="S" />
          <Panel bg_color="bg-grey5">
            <template slot="title">
            </template>
            <Title4><div class="summary" /></Title4>
            <Spacing value="S" />
            <BodyMedium><div class="extracted" /></BodyMedium>
          </Panel>
          <Spacing value="S" />
          <BodyMedium>By pressing the donate button you agree to the following
            <a href= "https://eyra.co" class="text-bodymedium font-body text-primary hover:text-grey1 underline focus:outline-none" >
              terms and conditions
            </a>.
          </BodyMedium>
          <Spacing value="S" />
          <button class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-grey1 focus:outline-none rounded pr-4 pl-4 bg-tertiary" data-role="donate-trigger">
            Donate extracted data
          </button>
        </div>

        <div class="script" hidden>
          <Spacing value="XL" />
          <Panel bg_color="bg-grey1">
            <Title3 color="text-white">Script</Title3>
            <BodyLarge color="text-white" >The script that is used to extract the relevant data from your data package</BodyLarge>
            <Spacing value="L" />
            <template slot="title">
            </template>
            <div class="text-white">
              <pre><code>{{ @tool.script }}</code></pre>
            </div>
          </Panel>
        </div>
      </div>
    </ContentArea>
    """
  end
end
