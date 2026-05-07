defmodule Systems.Admin.TypographyPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(active_menu_item: :admin)
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div class="w-full max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-title1 font-title1 mb-8">Typography Test Page</h1>
        <p class="text-bodymedium font-body text-grey2 mb-12">
          Preview all font styles with Nunito (> 20px) and Nunito Sans (≤ 20px).
          Use this page to evaluate readability, especially around the 20px threshold.
        </p>

        <%!-- Threshold Comparison Section --%>
        <section class="mb-16">
          <h2 class="text-title3 font-title3 mb-6 text-primary">Threshold Comparison (around 20px)</h2>
          <p class="text-bodysmall font-body text-grey2 mb-8">
            Compare styles just above and below the 20px threshold to evaluate the font transition.
          </p>

          <div class="space-y-6">
            <%!-- Title comparison --%>
            <div class="p-4 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-2">Title comparison</div>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">title5 (24px, Nunito Bold)</div>
                  <div class="text-title5 font-title5 text-left">The quick brown fox jumps</div>
                </div>
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">title6 (20px, Nunito Sans Bold)</div>
                  <div class="text-title6 font-title6">The quick brown fox jumps</div>
                </div>
              </div>
            </div>

            <%!-- Body comparison --%>
            <div class="p-4 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-2">Body comparison</div>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">bodylarge (24px, Nunito Light)</div>
                  <div class="text-bodylarge font-body">The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs.</div>
                </div>
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">bodymedium (20px, Nunito Sans Light)</div>
                  <div class="text-bodymedium font-body">The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs.</div>
                </div>
              </div>
            </div>

            <%!-- Intro comparison --%>
            <div class="p-4 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-2">Intro comparison</div>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">introdesktop (24px, Nunito Medium)</div>
                  <div class="text-introdesktop font-intro">The quick brown fox jumps over the lazy dog.</div>
                </div>
                <div class="p-3 bg-white rounded">
                  <div class="text-captionsmall text-grey2 mb-1">intro (20px, Nunito Sans Medium)</div>
                  <div class="text-intro font-intro">The quick brown fox jumps over the lazy dog.</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <%!-- Nunito Section (> 20px) --%>
        <section class="mb-16">
          <h2 class="text-title3 font-title3 mb-6 text-primary">Nunito (> 20px)</h2>
          <p class="text-bodysmall font-body text-grey2 mb-8">
            Rounded, softer font for display and headings. Used for larger text sizes.
          </p>

          <div class="space-y-4">
            <.font_sample
              name="title0"
              size="64px"
              weight="900 (Black)"
              text_class="text-title0"
              font_class="font-title0"
              sample="The quick brown fox"
            />
            <.font_sample
              name="title1"
              size="50px"
              weight="900 (Black)"
              text_class="text-title1"
              font_class="font-title1"
              sample="The quick brown fox jumps"
            />
            <.font_sample
              name="title2"
              size="40px"
              weight="900 (Black)"
              text_class="text-title2"
              font_class="font-title2"
              sample="The quick brown fox jumps over"
            />
            <.font_sample
              name="title3"
              size="32px"
              weight="900 (Black)"
              text_class="text-title3"
              font_class="font-title3"
              sample="The quick brown fox jumps over the lazy"
            />
            <.font_sample
              name="title4"
              size="28px"
              weight="900 (Black)"
              text_class="text-title4"
              font_class="font-title4"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="title5"
              size="24px"
              weight="700 (Bold)"
              text_class="text-title5"
              font_class="font-title5"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="bodylarge"
              size="24px"
              weight="300 (Light)"
              text_class="text-bodylarge"
              font_class="font-body"
              sample="The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs."
            />
            <.font_sample
              name="introdesktop"
              size="24px"
              weight="500 (Medium)"
              text_class="text-introdesktop"
              font_class="font-intro"
              sample="The quick brown fox jumps over the lazy dog."
            />
            <.font_sample
              name="quote"
              size="24px"
              weight="700 (Bold)"
              text_class="text-quote"
              font_class="font-quote"
              sample="The quick brown fox jumps over the lazy dog."
            />
          </div>
        </section>

        <%!-- Nunito Sans Section (≤ 20px) --%>
        <section class="mb-16">
          <h2 class="text-title3 font-title3 mb-6 text-primary">Nunito Sans (≤ 20px)</h2>
          <p class="text-bodysmall font-body text-grey2 mb-8">
            Neutral, cleaner font for better readability at smaller sizes.
          </p>

          <div class="space-y-4">
            <.font_sample
              name="title6"
              size="20px"
              weight="700 (Bold)"
              text_class="text-title6"
              font_class="font-title6"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="title7"
              size="16px"
              weight="700 (Bold)"
              text_class="text-title7"
              font_class="font-title7"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="bodymedium"
              size="20px"
              weight="300 (Light)"
              text_class="text-bodymedium"
              font_class="font-body"
              sample="The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!"
            />
            <.font_sample
              name="bodysmall"
              size="16px"
              weight="300 (Light)"
              text_class="text-bodysmall"
              font_class="font-body"
              sample="The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!"
            />
            <.font_sample
              name="subhead"
              size="20px"
              weight="500 (Medium)"
              text_class="text-subhead"
              font_class="font-subhead"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="intro"
              size="20px"
              weight="500 (Medium)"
              text_class="text-intro"
              font_class="font-intro"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="hint"
              size="20px"
              weight="300 (Light Italic)"
              text_class="text-hint"
              font_class="font-hint"
              sample="The quick brown fox jumps over the lazy dog"
            />
            <.font_sample
              name="button"
              size="18px"
              weight="700 (Bold)"
              text_class="text-button"
              font_class="font-button"
              sample="Button Text"
            />
            <.font_sample
              name="buttonsmall"
              size="16px"
              weight="700 (Bold)"
              text_class="text-buttonsmall"
              font_class="font-button"
              sample="Small Button Text"
            />
            <.font_sample
              name="label"
              size="16px"
              weight="700 (Bold)"
              text_class="text-label"
              font_class="font-label"
              sample="Form Label Text"
            />
            <.font_sample
              name="labelsmall"
              size="14px"
              weight="700 (Bold)"
              text_class="text-labelsmall"
              font_class="font-label"
              sample="Small Label Text"
            />
            <.font_sample
              name="caption"
              size="14px"
              weight="500 (Medium)"
              text_class="text-caption"
              font_class="font-caption"
              sample="Caption text for images and figures"
            />
            <.font_sample
              name="captionsmall"
              size="12px"
              weight="500 (Medium)"
              text_class="text-captionsmall"
              font_class="font-caption"
              sample="Small caption text"
            />
            <.font_sample
              name="footnote"
              size="16px"
              weight="500 (Medium)"
              text_class="text-footnote"
              font_class="font-footnote"
              sample="Footnote text for additional information"
            />
            <.font_sample
              name="link"
              size="16px"
              weight="500 (Medium)"
              text_class="text-link"
              font_class="font-link"
              sample="Link text style"
            />
            <.font_sample
              name="tablehead"
              size="14px"
              weight="700 (Bold)"
              text_class="text-tablehead"
              font_class="font-tablehead"
              sample="Table Header"
            />
            <.font_sample
              name="tablerow"
              size="14px"
              weight="400 (Regular)"
              text_class="text-tablerow"
              font_class="font-tablerow"
              sample="Table row content"
            />
            <.font_sample
              name="mono"
              size="20px"
              weight="300 (Light)"
              text_class="text-mono"
              font_class="font-body"
              sample="Monospace-style text"
            />
          </div>
        </section>

        <%!-- Paragraph Readability Test --%>
        <section class="mb-16">
          <h2 class="text-title3 font-title3 mb-6 text-primary">Paragraph Readability Test</h2>
          <p class="text-bodysmall font-body text-grey2 mb-8">
            Longer text samples to evaluate readability for body content.
          </p>

          <div class="space-y-8">
            <div class="p-6 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-4">bodylarge (24px, Nunito Light)</div>
              <p class="text-bodylarge font-body">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
              </p>
            </div>

            <div class="p-6 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-4">bodymedium (20px, Nunito Sans Light)</div>
              <p class="text-bodymedium font-body">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
              </p>
            </div>

            <div class="p-6 bg-grey5 rounded-lg">
              <div class="text-caption font-caption text-grey2 mb-4">bodysmall (16px, Nunito Sans Light)</div>
              <p class="text-bodysmall font-body">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
              </p>
            </div>
          </div>
        </section>
      </div>
    </.stripped>
    """
  end

  attr(:name, :string, required: true)
  attr(:size, :string, required: true)
  attr(:weight, :string, required: true)
  attr(:text_class, :string, required: true)
  attr(:font_class, :string, required: true)
  attr(:sample, :string, required: true)

  defp font_sample(assigns) do
    ~H"""
    <div class="p-4 bg-grey5 rounded-lg">
      <div class="flex flex-col sm:flex-row sm:items-baseline gap-2 mb-2">
        <span class="text-label font-label text-grey1">{@name}</span>
        <span class="text-captionsmall text-grey2">{@size}, {@weight}</span>
      </div>
      <div class={"#{@text_class} #{@font_class} text-grey1"}>
        {@sample}
      </div>
    </div>
    """
  end
end
