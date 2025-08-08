![logo](https://github.com/WernerPetrick/comet/blob/main/images/comet_text.png)

Static-first, component-aware site generation for Ruby. Comet converts Markdown + ERB shards into deterministic HTML, annotates interactive islands with a minimal data envelope, and defers JavaScript execution according to explicit hydration strategies.

## Technical Overview

| Layer | Responsibility | Implementation |
|-------|---------------|----------------|
| Content Ingestion | Parse Markdown + front matter | Redcarpet + front_matter_parser + Rouge |
| Component Expansion | Replace `<%= shard ... %>` invocations | Regex + ERB + JSON serialization |
| Layout Application | Wrap page content | ERB layout context (binding sandbox) |
| Asset Pipeline | Compile SCSS / copy assets | SassC + FileUtils |
| Output Routing | Clean URLs, nested index pages | Path rewriting (page -> /page/index.html) |
| Hydration Registry | Collect shard metadata | Inline `<script>` pushing into `window.__COMET_SHARDS__` |
| Client Activation | Schedule hydration by strategy | Single hydration manager script |
| Dev Feedback Loop | File watching + incremental rebuild | Listen + WEBrick |

## Data Flow (Build Pipeline)

```
Markdown (.md)
  └─> Front matter extraction
        └─> Markdown → HTML (Redcarpet)
              └─> Shard scan & expansion
                     └─> Layout wrapping
                           └─> Dist write (clean URL mapping)
Assets (SCSS/JS/static) ────────────────┘
Hydration script emission ─────────────┘
```

Each page is processed independently; no global dependency graph is required for correctness. The build is idempotent with respect to source tree state.

## Shard Contract

Inside any Markdown (post-rendered via ERB):

```erb
<%= shard "button", props: { text: "Save", variant: "primary" }, hydrate: "visible" %>
```

Server expansion produces:

```html
<div id="shard-button-1234" data-shard="button" data-hydrate="visible" data-props='{"text":"Save","variant":"primary"}'>
  <!-- Rendered shard HTML -->
  <button class="btn btn-primary">Save</button>
</div>
<script>window.__COMET_SHARDS__ = window.__COMET_SHARDS__ || []; window.__COMET_SHARDS__.push({id:"shard-button-1234",name:"button",strategy:"visible",props:{"text":"Save","variant":"primary"}});</script>
```

### Server-Side Helpers Available in Shards

| Helper | Purpose |
|--------|---------|
| `prop(key, default=nil)` | Fetch prop with optional fallback |
| `hydrate?` | Boolean: hydration requested (strategy != nil) |
| `asset_path(rel)` | Resolves to `/assets/rel` at runtime |
| `site` | Site metadata OpenStruct (e.g. `site.title`) |

Isolation: Shards render in a fresh ERB context (no implicit leakage between shards) and receive only the props supplied at invocation time plus shared helpers.

## Hydration Strategies (Runtime Semantics)

| Strategy | Trigger | Ordering Guarantees |
|----------|---------|---------------------|
| immediate | Hydration script evaluation / DOMContentLoaded microtask | Executes before `load` and `visible` activations |
| load | `window.onload` | After all immediate activations complete |
| visible | IntersectionObserver entry | May interleave post-load based on scroll/viewport |

Runtime attaches a single observer instance for all `visible` shards and tears it down once all relevant islands have hydrated.

### Custom Client Hooks

Developers may define any of:

| Global | Signature | Invocation Context |
|--------|-----------|--------------------|
| `window.hydrate_<shardName>` | `(element, props)` | After base activation, if defined |
| `window.CometActions[action]` | `(event, props)` | When a descendant with `data-action` is clicked |

This avoids a global event bus while preserving explicit opt-in per component.

## Layout Context

Layout ERB receives a `LayoutContext` exposing:

| Method | Value |
|--------|-------|
| `content` | Final HTML for the page body (post-shard expansion) |
| `title` | Page front matter `title` or fallback to `site.title` |
| `description` | Front matter `description` or site default |
| `frontmatter` | Raw front matter hash |
| `site` | Site metadata object |
| `asset_path(name)` | `/assets/name` |

No implicit global variables are injected; explicitness of binding reduces collision depth.

## Clean URL Mapping Logic

| Source | Output Path |
|--------|-------------|
| `index.md` | `/index.html` |
| `about.md` | `/about/index.html` (served as `/about/`) |
| `guides/setup.md` | `/guides/setup/index.html` |

## CSS Framework Modes

At project generation (`--css=`) the template swaps in one of:

| Mode | Asset Artifacts | Notes |
|------|-----------------|-------|
| bulma | `styles.scss` importing CDN Bulma + overrides | Default profile |
| bootstrap | `styles.scss` with Bootstrap CDN import | Parallel semantic layer |
| tailwind | `styles.css` + `tailwind.config.js` placeholder | Requires future JIT integration (no @apply processing yet) |
| custom | Minimal `styles.scss` + neutral JS scaffold | For greenfield design systems |

Framework-specific shard variants (e.g., button/card) can override generic ones during scaffold.

## Build System (lib/comet/build_system.rb)

| Phase | Function | Notes |
|-------|----------|-------|
| Page enumeration | `markdown_files` | Glob under `pages/` |
| Parse + render | `MarkdownProcessor` | Redcarpet options: fenced code, tables, autolink |
| Shard expansion | `ShardProcessor.process` | Regex: `<%=\s*shard\s*"name"...%>` |
| Layout wrapping | `BuildSystem#apply_layout` | Fallback default layout if missing |
| Asset handling | `copy_assets` | SCSS compiled to compressed CSS via SassC |
| Hydration script | `generate_hydration_script` | Deterministic single file |

No concurrency is currently leveraged; CPU-bound phases are sufficiently fast for typical content scales. Future parallelization boundary surfaces: per-page render, SCSS compilation.

## Config DSL (`comet.config.rb`)

Current supported keys (OpenStruct based):

```ruby
site.title = "My Site"
site.description = "Description"
# Reserved for future: build.output_dir, build.src_dir, etc.
```

All configuration resolves prior to build; dynamic mutation during build is intentionally not supported.

## Internal Regex (Shard Detection)

```
/<%=\s*shard\s*"([a-zA-Z0-9_\-]+)"\s*(?:,\s*([^%]+?))?%>/
```
Groups:
1. Shard name
2. Options segment (Ruby hash literal subset) – evaluated via `eval` in a constrained binding (future hardening recommended).

## Security / Hardening Considerations

| Area | Current State | Potential Hardening |
|------|---------------|---------------------|
| Option evaluation | Uses `eval` on options hash | Replace with safe parser (JSON / custom scanner) |
| Shard template ERB | Full ERB | Sandbox / frozen bindings |
| Asset paths | Direct copy | Fingerprinting & whitelist |
| Client props | Raw JSON string | Optional schema validation + size guard |

## Performance Characteristics (Qualitative)

| Metric | Influence Factors | Current Approach |
|--------|-------------------|------------------|
| TTFB | Ruby render + IO | Single-pass synchronous pipeline |
| FCP | Static HTML + single CSS | Inlines only minimal metadata; external CSS consolidated |
| JS Cost | Hydration scope | Strategy-based gated execution |
| Rebuild Latency | File count | Full rebuild; no incremental graph yet |

## Extension Points (Planned Surface)

| Domain | Proposal |
|--------|----------|
| Incremental Builds | Track dependency map (page ↔ shards ↔ assets) |
| Tailwind JIT | Integrate CLI invocation & purge stage |
| Collections | Structured content grouping with computed indexes |
| Markdown Plugins | Hook chain for AST transforms pre-shard expansion |
| Asset Fingerprinting | Hash-based naming + manifest injection |
| Image Pipeline | Responsive variants + `srcset` emission |
| Prop Validation | Optional schemas (JSON Schema / dry-types) |

## Testing Surface

RSpec specs validate at least shard rendering and hydration strategy correctness. Additional desirable test vectors: layout resolution precedence, clean URL mapping, SCSS compilation error handling, option parsing edge cases.

## Roadmap Snapshot

| Stage | Focus |
|-------|-------|
| 0.1.x | Core pipeline stability, shard ergonomics |
| 0.2.x | Safe option parsing, incremental watch graph |
| 0.3.x | Tailwind processing integration, asset fingerprinting |
| 0.4.x | Collections + content querying layer |
| 0.5.x | Image optimization + responsive pipeline |

## Observability Ideas

Lightweight diagnostics (proposed): build timing summary, per-page render durations, shard count histogram, hydration strategy distribution, emitted CSS/JS size report.

## Limitations (Current)

| Limitation | Impact |
|------------|--------|
| No incremental builds | Full rebuild on any change |
| `eval` for shard options | Potential injection risk (trusted author assumption) |
| Single stylesheet target | No code splitting for styles |
| Tailwind placeholder only | No processing of `@apply` / purge |
| No image pipeline | Raw image copies with no optimization |

## Minimal Example (End-to-End)

```
src/pages/index.md
---
title: Home
layout: default
---

# Welcome

<%= shard "hero", props: { title: "Fast", subtitle: "Static-first" }, hydrate: "visible" %>
```

```
src/shards/hero.erb
<section class="hero">
  <h1><%= prop(:title) %></h1>
  <p><%= prop(:subtitle) %></p>
</section>
```

Result: `/index.html` with static markup + deferred hydration metadata consumed by the unified client script.

## License

MIT – see `LICENSE`.

---

Concise pipeline, explicit contracts, minimal runtime surface.
