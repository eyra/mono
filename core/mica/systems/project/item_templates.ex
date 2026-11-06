defmodule Systems.Project.ItemTemplates do
  use Mica.Enums.Base,
      {:project_item_templates,
       [:paper_screening, :benchmark_challenge, :data_donation, :questionnaire]}

  alias Systems.Assignment

  @doc "Name of a built-in template or of an assignment template added by the SaaS."
  def name(template) do
    if contains(template) do
      translate(template)
    else
      Assignment.TemplateExtension.title(template)
    end
  end

  @doc "Selector labels of the assignment templates added by the SaaS that are enabled."
  def extension_labels do
    Enum.map(Assignment.TemplateExtension.enabled(), fn module ->
      %{id: module.id(), value: name(module.id()), active: false}
    end)
  end
end
