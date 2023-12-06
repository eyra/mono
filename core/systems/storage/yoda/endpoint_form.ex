defmodule Systems.Storage.Yoda.EndpointForm do
  use Systems.Storage.EndpointForm.Helper, Systems.Storage.Yoda.EndpointModel

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_yoda_endpoint_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
      <.form id={"#{@id}_yoda_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.text_input form={form} field={:url} label_text={dgettext("eyra-storage", "yoda.url.label")} debounce="0" placeholder="https://{portal}/{research_group}/{your_folder}>"/>
        <.text_input form={form} field={:user} label_text={dgettext("eyra-storage", "yoda.user.label")} debounce="0" />
        <.password_input form={form} field={:password} label_text={dgettext("eyra-storage", "yoda.password.label")} debounce="0" />
      </.form>
    </div>
    """
  end
end
