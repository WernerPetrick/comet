<p align="center">
  <img src="https://github.com/WernerPetrick/comet/blob/main/images/Comet_logo.png" alt="Comet Logo" width="600">
</p>

Comet is a static‑first site framework for Ruby. Write pages in Markdown, drop in reusable ERB shards (components), wire light interactivity via Stimulus controllers, and choose exactly when each hydrates. Output is plain, cacheable HTML + tiny, opt‑in JavaScript.

## Why Comet

Simple mental model: Content → Components → Layout → Assets → Ship. No bundler maze, no virtual DOM, no opaque pipelines. Just Ruby, Markdown, ERB, and a pinch of targeted JavaScript.

## Core Ideas

**Pages (Markdown)** — Each file has optional front matter (`title`, `layout`, etc.).

**Shards (ERB Components)** — Reusable snippets invoked inline:
```erb
<%= shard "button", props: { text: "Save", variant: "primary" }, hydrate: "visible" %>
```

**Layouts** — Light ERB shells wrapping page content.

**Selective Hydration** — Strategies: `immediate`, `load`, `visible`. Only requested shards wake up (IntersectionObserver for `visible`).

**Stimulus Integration** — Each shard name auto‑maps to a Stimulus controller `shard-<name>` (override with `controller:`). Controllers live in `src/assets/controllers/`.

**Collections & Tags** — Generalized content collections with dynamic slug pages, tag indexes, and optional JSON feeds.

**Styling** — Pick Bulma (default), Bootstrap, Tailwind placeholder, or a minimal custom profile when scaffolding.

**Assets** — SCSS compiled to a single stylesheet; JS copied as-is.

## Quick Glance

Project anatomy:
```
src/
  pages/    # Markdown content
  shards/   # ERB component templates
  layouts/  # Page wrappers
  assets/   # styles.scss (or .css), app.js, controllers/, vendor/
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

## Configuration Overview

`comet.config.rb` sets site metadata and defines collections.

Example:
```ruby
site.title       = "My Site"
site.description = "Fast & minimal"

collections do
  collection :docs, source: "collections/docs", template: "pages/docs/[slug].md", tags: true, feed: true
  collection :guides, source: "collections/guides", template: "pages/guides/[slug].md"
end
```

Collection options:
- `source:` folder containing Markdown entries (each file becomes an item)
- `template:` dynamic page template path containing `[slug]`
- `tags: true` generate per‑tag index pages
- `feed: true` generate a JSON Feed (`/docs/feed.json`)

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
| Reusable components | Plain ERB shards |
| Collections system | Dynamic `[slug]` templates + tags + feeds |
| Stimulus controllers | Auto shard → controller mapping |
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

## Creating a Shard

1. Create `src/shards/alert.erb`:
```erb
<div class="alert <%= prop(:variant,'info') %>">
  <strong><%= prop(:title,'Notice') %>:</strong> <%= prop(:message,'Hello') %>
</div>
```
2. Invoke inside Markdown:
```erb
<%= shard "alert", props: { title: "Heads up", message: "Saved", variant: "success" }, hydrate: "immediate" %>
```
3. Add interactivity by creating `src/assets/controllers/shard_alert_controller.js` (optional if you need JS):
```js
(() => {
  if(!window.Stimulus) return;
  if(!window.__COMET_STIMULUS_APP__) window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
  const app = window.__COMET_STIMULUS_APP__;
  app.register('shard-alert', class extends window.Stimulus.Controller {
    connect(){ /* wire timers, events, etc */ }
  });
})();
```

## Creating a Stimulus Controller

1. File: `src/assets/controllers/shard_counter_controller.js`
```js
(() => {
  if(!window.Stimulus) return;
  if(!window.__COMET_STIMULUS_APP__) window.__COMET_STIMULUS_APP__ = window.Stimulus.Application.start();
  const app = window.__COMET_STIMULUS_APP__;
  app.register('shard-counter', class extends window.Stimulus.Controller {
    static values = { start: Number };
    connect(){ this.count = this.hasStartValue ? this.startValue : 0; this.render(); }
    increment(){ this.count++; this.render(); }
    render(){ const n=this.element.querySelector('[data-role="count"]'); if(n) n.textContent=this.count; }
  });
})();
```
2. Shard ERB: `src/shards/counter.erb`
```erb
<div data-controller="shard-counter">
  <span data-role="count"></span>
  <button type="button" data-action="click->shard-counter#increment">+1</button>
</div>
```
3. Invoke:
```erb
<%= shard "counter", props: { start: 5 }, hydrate: "immediate" %>
```

## Collections & Tags Walkthrough

1. Configure collection in `comet.config.rb` (see above).
2. Add Markdown files under `src/collections/docs/` (e.g. `intro.md`).
3. Ensure dynamic template exists: `src/pages/docs/[slug].md`:
```markdown
---
title: {{ slug | capitalize }}
---

<h1><%= frontmatter['title'] %></h1>
<%= content %>
```
4. (Optional) Add `tags: true` and include `tags: ["alpha","beta"]` in each item front matter to generate `/tags/<tag>/` pages.
5. (Optional) `feed: true` produces `/docs/feed.json` (JSON Feed v1).

## Legacy Blog

A legacy blog helper remains temporarily; prefer the generalized collections system for new content. Blog helper will be deprecated.

## Navigation Scaffolding

Run:
```bash
comet nav:init
```
Generates `src/pages/navbar/` with example docs; restart dev server to see structured nav.

## Development Workflow

```bash
gem install comet   # or use Gemfile + bundle
comet new mysite
cd mysite
comet dev           # start dev server (default :3000)
# edit content/shards
comet build         # produce dist/ for deploy
```

## Deploy

Upload the `dist/` folder to any static host (Netlify, GitHub Pages, Cloudflare Pages, S3 + CDN, etc.).

## License

MIT – see `LICENSE`.

---

Static first. Components when you need them. JavaScript only where it counts.
