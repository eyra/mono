# Prism Framework - Handover Document

## What is Prism?

Prism is a new Tailwind-based UI framework being extracted from this codebase to be reused across multiple scientific software projects. It's designed to be:
- **Playful but professional** - Modern, approachable design for scientific software
- **Brand-neutral** - Decoupled from Eyra branding for maximum third-party adoption
- **Easy to adopt** - Hybrid approach with both Tailwind preset and ready-made component classes

## Architecture Decisions Made

| Decision | Choice |
|----------|--------|
| **Name** | Prism |
| **Approach** | Hybrid (Tailwind preset + component CSS classes) |
| **Location** | `/packages/prism/` subfolder (will become separate repo when stable) |
| **Package type** | NPM package |

## Relationship: Prism vs Pixel

- **Prism** = Pure CSS/Tailwind (the styling) - framework-agnostic
- **Pixel** = Elixir/Phoenix LiveView components (the behavior) - uses Prism classes

After extraction, Pixel components become thinner wrappers:

```elixir
# Before (verbose Tailwind in Pixel)
def primary(assigns) do
  ~H"""
  <div class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded bg-primary">
    <%= @label %>
  </div>
  """
end

# After (Pixel using Prism classes)
def primary(assigns) do
  ~H"""
  <div class="prism-btn prism-btn-primary">
    <%= @label %>
  </div>
  """
end
```

## Target Folder Structure

```
packages/prism/
├── package.json                    # NPM package config
├── tailwind.preset.js              # Tailwind preset (colors, fonts, spacing)
├── css/
│   ├── base.css                    # @font-face, resets, utilities
│   └── components.css              # Button, input, radio, dropdown classes
├── fonts/
│   ├── Nunito-VariableFont_wght.woff2
│   ├── NunitoSans-VariableFont_wght.woff2
│   └── NunitoSans-Italic-VariableFont_wght.woff2
└── README.md
```

## What to Extract (Phase 1 - Generic Only)

### Foundation (from `assets/tailwind.config.js`)
- Colors: primary, secondary, tertiary, greys, status colors
- Typography: Nunito / Nunito Sans font families, sizes, weights
- Spacing tokens
- Custom utilities (viewport height, safe areas, scrollbar)

### Components (from `frameworks/pixel/components/`)
- **Buttons**: primary, secondary, plain (see `button_face.ex`)
- **Inputs**: text, email, password, number, date (see `form.ex`)
- **Textarea**
- **Radio group** (see `radio_group.ex`, `form.ex`)
- **Dropdown/select**
- **Spinner**

### What Stays in Pixel (app-specific)
- Menu components (menu_home, menu_item)
- Photo/image upload components
- WYSIWYG editor styles
- LiveView-specific integrations

## Key Files to Reference

Current styling sources in this codebase:
- `/assets/tailwind.config.js` - All design tokens
- `/assets/css/app.css` - Font faces, WYSIWYG styles
- `/priv/static/fonts/` - Font files
- `/frameworks/pixel/components/button.ex` - Button component
- `/frameworks/pixel/components/button_face.ex` - Button styling variants
- `/frameworks/pixel/components/form.ex` - Input components
- `/frameworks/pixel/components/text.ex` - Typography components
- `/frameworks/pixel/components/radio_group.ex` - Radio styling

## Consumer Usage (Target)

After Prism is complete, consumers will use it like this:

```javascript
// tailwind.config.js
module.exports = {
  presets: [require('prism-ui/tailwind.preset')],
  content: [...]
}
```

```css
/* app.css */
@import 'prism-ui/css/base.css';
@import 'prism-ui/css/components.css';
@tailwind components;
@tailwind utilities;
```

```html
<!-- Usage -->
<button class="prism-btn prism-btn-primary">Click me</button>
<input class="prism-input" type="text" placeholder="Enter text">
```

## Tasks To Complete

1. [ ] Create Prism folder structure (`/packages/prism/`)
2. [ ] Create `package.json`
3. [ ] Extract Tailwind preset (`tailwind.preset.js`)
4. [ ] Create base CSS with font-face declarations (`css/base.css`)
5. [ ] Copy font files to `fonts/`
6. [ ] Create button component classes (`css/components.css`)
7. [ ] Create input component classes
8. [ ] Create radio/dropdown classes
9. [ ] Configure this repo to use Prism as dependency
10. [ ] Update Pixel components to use Prism classes
11. [ ] Test that everything still works

## This Worktree

- **Location**: `/Users/melle/projects/eyra/mono-prism`
- **Branch**: `feature/prism`
- **Port**: 4001 (configured in `config/dev.secret.exs`)
- **Base branch**: `develop`

## Notes

- Aim for easy adoption - component classes should be intuitive
- Keep it minimal first - only the most generic components
- Font files are Nunito (variable font) - already have Open Font License
