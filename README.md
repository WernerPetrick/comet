![logo](https://github.com/WernerPetrick/comet/blob/main/images/Comet_logo.png)

Comet is a static‑first site framework for Ruby. Write pages in Markdown, drop in reusable ERB shards (components), and choose exactly when each one hydrates in the browser. The output is plain, cacheable HTML plus a small hydration script for the interactive bits you opt into.

## Why Comet

Simple mental model: Content → Components → Layout → Assets → Ship. No bundler maze, no virtual DOM, no opaque pipelines. Just Ruby, Markdown, ERB, and a pinch of targeted JavaScript.

## Core Ideas

**Pages (Markdown)** — Each file has optional front matter (`title`, `layout`, etc.).

**Shards (ERB Components)** — Reusable snippets invoked inline:
```erb
<%= shard "button", props: { text: "Save", variant: "primary" }, hydrate: "visible" %>
```

**Layouts** — Light ERB shells wrapping page content.

**Selective Hydration** — Strategies: `immediate`, `load`, `visible`. Only the chosen shards wake up.

**Styling** — Pick Bulma (default), Bootstrap, Tailwind placeholder, or a minimal custom profile when scaffolding.

**Assets** — SCSS compiled to a single stylesheet; JS copied as-is.

## Quick Glance

Project anatomy:
```
src/
  pages/    # Markdown content
  shards/   # ERB component templates
  layouts/  # Page wrappers
  assets/   # styles.scss, app.js, images
public/     # Static passthrough files
dist/       # Generated site output
comet.config.rb
```

Minimal page:
```markdown
---
title: Home
layout: default
---

# Hello

<%= shard "cta", props: { text: "Start" }, hydrate: "load" %>
```

Shard template:
```erb
<!-- src/shards/cta.erb -->
<button class="btn" data-action="track" <%= 'data-interactive="true"' if hydrate? %>>
  <%= prop(:text, 'Click') %>
</button>
```

## Hydration at a High Level

During build each shard call is rendered to static HTML and wrapped with a small data block describing its name, props, and strategy. A single client script reads that list and activates only what you requested. "Visible" shards use an IntersectionObserver, "load" waits for the full load event, and "immediate" runs right away.

## Helpers Available in Shards

- `prop(:key, default=nil)` — Access props with fallback
- `hydrate?` — True if a hydration strategy was specified
- `asset_path("file")` — Resolves to `/assets/file`
- `site` — Site metadata from `comet.config.rb`

## Configuration (Simple Today)

`comet.config.rb` currently focuses on metadata:
```ruby
site.title = "My Site"
site.description = "Fast & minimal"
```
Additional build knobs (custom dirs, etc.) are reserved for later versions.

## CSS Framework Choice

When generating a project you can select:
- Bulma (opinionated defaults + example shards)
- Bootstrap
- Tailwind (placeholder; utility processing roadmap)
- Custom (lightweight starter)

Each mode swaps in appropriate `styles.*` and shard variants where available.

## What You Get Out of the Box

| Capability | Notes |
|------------|-------|
| Fast static HTML | Every page pre-rendered |
| Reusable components | Plain ERB, easy to read |
| Targeted JS | Single hydration runtime |
| Clean URLs | `about.md` → `/about/` |
| SCSS support | Compiled + compressed |
| Hot dev server | Auto rebuild on change |

## Design Principles

- Ship static HTML first
- Opt into interactivity intentionally
- Keep components transparent and debuggable
- Avoid hidden global state
- Favor explicit over clever

## Limitations (Current)

- No incremental build graph yet (full rebuild on any change)
- Shard option parsing still uses `eval` (trusted author assumption)
- Tailwind integration is a placeholder (no JIT / purge)
- Single stylesheet bundle (no code splitting)
- No image optimization pipeline yet

## Example End-to-End Flow

1. Author `index.md` with a shard call.
2. Build: Markdown → HTML → shards rendered → layout applied.
3. Assets compiled and copied.
4. Hydration script added once.
5. Serve or deploy `dist/` anywhere (CDN, object storage, static host).

## License

MIT – see `LICENSE`.

---

Static first. Components when you need them. JavaScript only where it counts.
