---
title: Components
order: 2
---

# Components (Shards)

Shards are small ERB templates that receive a `props` hash and helper methods.

Example shard invocation inside Markdown:

```ruby
<%= shard "button", 
    props: { text: "Click", variant: "primary" }, 
    hydrate: "visible"
%>
```

They render server-side, and can hydrate later in the browser based on the chosen strategy.
