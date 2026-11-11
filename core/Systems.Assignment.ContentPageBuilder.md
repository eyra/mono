# `Systems.Assignment.ContentPageBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/content_page_builder.ex#L1)

  Assignment is a generic concept with a template pattern. The content page is therefor rendered with optional components.
  This builder module supports several specials with each a specific View Model.
  For a full overview of the template feature see `Systems.Assignment.Template`.

# `handle_close`

# `handle_open`

# `handle_publish`

# `handle_retract`

# `view_model`

  Returns a view model based on the templates defined in:
  * Paper Screening: `Systems.Assignment.TemplatePaperScreening`
  * Benchmark Challenge: `Systems.Assignment.TemplateBenchmarkChallenge`
  * Data Donation: `Systems.Assignment.TemplateDataDonation`
  * Questionnaire: `Systems.Assignment.TemplateQuestionnaire`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
