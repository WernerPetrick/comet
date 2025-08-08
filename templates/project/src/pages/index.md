---
title: "Welcome to <%= config[:name] %>"
layout: default
---

# Welcome to Comet!

This is your first Comet page. It's written in Markdown and can include shards (components).

## Example Shard

Here's a simple button shard:

<%= shard "button", props: { text: "Get Started", variant: "primary" }, hydrate: "load" %>

## Features

- **Markdown-first** - Write content in Markdown
- **Component System** - Reusable shards with ERB
- **Selective Hydration** - Control when components become interactive
- **Sass Support** - Built-in SCSS/Sass compilation
- **Hot Reload** - Instant updates during development

## Getting Started

1. Edit this file at `src/pages/index.md`
2. Create shards in `src/shards/`
3. Add styles to `src/assets/styles.scss`
4. Run `comet dev` to start developing

### OpenGraph / Twitter Cards

Set global social defaults in `comet.config.rb` (e.g. `site.url`, `site.twitter`, `site.og_image`).

Override per page by adding front matter keys:

```
---
title: "Custom Title"
description: "Custom description up to ~200 characters."
image: /assets/og-custom.png   # or og_image: /assets/og-custom.png
---
```

If no `image` is provided, it falls back to `og_image` or `site.og_image`.

Happy building!
