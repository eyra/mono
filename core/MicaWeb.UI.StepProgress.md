# `MicaWeb.UI.StepProgress`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/ui/step_progress.ex#L1)

  Horizontal progress through a fixed number of steps: one Prism step indicator per
  step on a track that fills up to the current step. The steps are not selectable.
  A finished step shows a check, the current step its number, an upcoming step a
  grey check.

  Each step is `%{number: integer(), label: String.t(), status: :complete | :current |
  :incomplete}`; the label is for screen readers.

# `step_number`

The current step's number, larger, e.g. before the step's title.
## Attributes

* `number` (`:integer`) (required)

# `step_progress`

## Attributes

* `steps` (`:list`) (required)
* `testid` (`:string`) - Defaults to `"step-progress"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
