defmodule Systems.Storage.AWS.EndpointForm do
  use Systems.Storage.EndpointForm.Helper, Systems.Storage.AWS.EndpointModel

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_aws_endpoint_content"} phx-hook="LiveContent" data-show-errors={@show_errors}>
      <.form id={"#{@id}_aws_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.text_input form={form} field={:access_key_id} label_text={dgettext("eyra-storage", "aws.access_key_id.label")} />
        <.password_input form={form} field={:secret_access_key} label_text={dgettext("eyra-storage", "aws.secret_access_key.label")} />
        <.text_input form={form} field={:s3_bucket_name} label_text={dgettext("eyra-storage", "aws.s3_bucket_name.label")} />
        <.text_input form={form} field={:region_code} label_text={dgettext("eyra-storage", "aws.region_code.label")} />
      </.form>
    </div>
    """
  end
end
