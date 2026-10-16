defmodule Systems.Storage.Yoda.EndpointForm do
  use Systems.Storage.EndpointForm.Helper, Systems.Storage.Yoda.EndpointModel

  import Systems.Storage.Html

  @impl true
  def render(assigns) do
    ~H"""
      <div>
      <.form id={"#{@id}_yoda_endpoint_form"} :let={form} for={@changeset} phx-change="change" phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col gap-4">
          <.text_input form={form} field={:user} label_text={dgettext("eyra-storage", "yoda.user.label")} debounce="0" reserve_error_space={false} />
          <.password_input form={form} field={:password} label_text={dgettext("eyra-storage", "yoda.password.label")} debounce="0" reserve_error_space={false} />
          <.text_input form={form} field={:url} label_text={dgettext("eyra-storage", "yoda.url.label")} placeholder="https://{portal}/{research_group}/{your_folder}>" debounce="0" reserve_error_space={false} />
          <div class="flex flex-row gap-4 items-center mt-2">
            <Button.dynamic_bar buttons={[@submit_button]} />
            <%= if @show_status do %>
              <.account_status connected?={@connected?}/>
            <% end %>
          </div>
        </div>
      </.form>
      </div>
    """
  end
end
