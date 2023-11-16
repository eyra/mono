defmodule Systems.Storage.Centerdata.EndpointForm do
  use Systems.Storage.EndpointForm.Helper, Systems.Storage.Centerdata.EndpointModel

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_centerdata_endpoint_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
      <.form id={"#{@id}_centerdata_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.url_input
          form={form}
          field={:url}
          label_text={dgettext("eyra-storage", "centerdata.url.label")}
        />
      </.form>
    </div>
    """
  end
end
