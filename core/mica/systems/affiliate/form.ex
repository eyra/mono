defmodule Systems.Affiliate.Form do
  use CoreWeb.LiveForm

  alias Systems.Affiliate

  @impl true
  def update(%{affiliate: entity}, socket) do
    {
      :ok,
      socket
      |> assign(
        entity: entity,
        test: %{
          callback_url: %{success: false, error: nil},
          redirect_url: %{success: false, error: nil}
        }
      )
      |> init_changeset()
      |> test_urls()
    }
  end

  defp init_changeset(%{assigns: %{entity: entity}} = socket) do
    assign(socket, changeset: Affiliate.Model.changeset(entity, %{}))
  end

  def handle_event(
        "save",
        %{"model" => attrs},
        %{assigns: %{entity: entity}} = socket
      ) do
    changeset = Affiliate.Model.changeset(entity, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
      |> test_urls()
    }
  end

  defp test_urls(socket) do
    socket
    |> test_url(:callback_url)
    |> test_url(:redirect_url)
  end

  defp test_url(%{assigns: %{entity: entity, test: test}} = socket, field) do
    url = Map.get(entity, field)

    test =
      case Affiliate.Model.validate_url(url) do
        {:ok, url} ->
          case Affiliate.Public.validate_url(url) do
            {:ok, _} ->
              %{test | field => %{success: true, error: nil}}

            {:error, _error} ->
              %{
                test
                | field => %{
                    success: false,
                    error: dgettext("eyra-affiliate", "invalid_url.unreachable")
                  }
              }
          end

        {:error, error} ->
          %{test | field => %{success: false, error: error}}
      end

    socket |> assign(test: test)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={form} for={@changeset} phx-change="save" phx-submit="save" phx-target={@myself}>
          <Text.title4><%= dgettext("eyra-affiliate", "redirect_url.title") %></Text.title4>
          <.spacing value="XS" />
          <Text.body><%= dgettext("eyra-affiliate", "redirect_url.body") %></Text.body>
          <.spacing value="XS" />
          <.url_input form={form} field={:redirect_url} placeholder={dgettext("eyra-affiliate", "redirect_url.placeholder")} reserve_error_space={false}/>
          <.spacing value="XXS" />
          <div class="flex flex-row items-center gap-3">
            <div :if={@test.redirect_url.error} class="text-caption font-caption text-warning leading-6">
              <%= @test.redirect_url.error %>
            </div>
            <div :if={@test.redirect_url.success} class="text-caption font-caption text-success leading-6">
              <%= dgettext("eyra-affiliate", "test.success") %>
            </div>
          </div>

          <.spacing value="XS" />
          <Text.body><%= dgettext("eyra-affiliate", "platform_name.body") %></Text.body>

          <.spacing value="S" />
          <.text_input form={form} field={:platform_name} label_text={dgettext("eyra-affiliate", "platform_name.label")} placeholder={dgettext("eyra-affiliate", "platform_name.placeholder")} reserve_error_space={false}/>

          <.spacing value="M" />

          <Text.title4><%= dgettext("eyra-affiliate", "callback_url.title") %></Text.title4>
          <.spacing value="XS" />
          <Text.body><%= dgettext("eyra-affiliate", "callback_url.body") %></Text.body>
          <.spacing value="XS" />
          <.url_input form={form} field={:callback_url} placeholder={dgettext("eyra-affiliate", "callback_url.placeholder")} reserve_error_space={false}/>

          <.spacing value="XXS" />
          <div class="flex flex-row items-center gap-3">
            <div :if={@test.callback_url.error} class="text-caption font-caption text-warning leading-6">
              <%= @test.callback_url.error %>
            </div>
            <div :if={@test.callback_url.success} class="text-caption font-caption text-success leading-6">
              <%= dgettext("eyra-affiliate", "test.success") %>
            </div>
          </div>
      </.form>
    </div>
    """
  end
end
