defmodule Systems.Storage.Azure.EndpointForm do
  use Systems.Storage.EndpointForm.Helper, Systems.Storage.Azure.EndpointModel

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_azure_endpoint_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
      <.form id={"#{@id}_azure_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.text_input form={form} field={:account_name} label_text={dgettext("eyra-storage", "azure.account_name.label")} />
        <.text_input form={form} field={:container} label_text={dgettext("eyra-storage", "azure.container.label")} />
        <.text_input form={form} field={:sas_token} label_text={dgettext("eyra-storage", "azure.sas_token.label")} />
      </.form>
    </div>
    """
  end
end
