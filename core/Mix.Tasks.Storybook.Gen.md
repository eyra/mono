# `mix storybook.gen`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mix/tasks/storybook.gen.ex#L1)

Writes a `*.story.exs` for every public function component (`def` with `attr`/`slot`
declarations) defined under SOURCE_DIR that has no story in CONTENT_DIR yet. Existing stories are
never touched, so curate a story by editing its generated file.

    mix storybook.gen SOURCE_DIR CONTENT_DIR [--prefix MODULE] [--check]

Each module gets one folder named after it, minus `--prefix`, with a story per component:
with `--prefix Frameworks.Pixel`, `Frameworks.Pixel.Button.dynamic/1` becomes
`CONTENT_DIR/button/dynamic.story.exs` and `Frameworks.Pixel.Button.Face.label/1`
becomes `CONTENT_DIR/button.face/label.story.exs`. The folders stay flat, so a function never
shares its storybook path with a nested module of the same name.

The `:default` variation fills required attributes from their `examples:` or `values:`, or with
a placeholder for their type, and gives the default slot some text.

`--check` writes nothing and fails when a story is missing.

LiveViews and live components are skipped: their components render with the state of the
process, so a story for them is written by hand (`use PhoenixStorybook.Story, :live_component`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
