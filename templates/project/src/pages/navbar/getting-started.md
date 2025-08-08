---
title: Getting Started
order: 1
---

# Getting Started

A brief primer on how to begin with your new Comet site.

1. Write Markdown in `src/pages/`.
2. Add components (shards) in `src/shards/`.
3. Run `comet dev` for live reload.
4. Build with `comet build`.

<%= shard "button", props: { text: "Explore", variant: "primary" }, hydrate: "load" %>
