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

### Shards & Meta

You can conditionally set meta via front matter, then reference shard output; shards themselves don’t alter OG tags—use front matter `title`, `description`, and `image`.

---

## Advanced Example: Live Filter List (Stimulus)

Live demo (interactive):

<%= shard "filter_list", props: { items: ["Alpha", "Beta", "Gamma", "Delta", "Comet", "Component", "Counter", "Filtering", "List", "Stimulus", "Ruby", "Static", "Site"] }, hydrate: "immediate" %>

---

Below is a more complex shard that demonstrates:

- Passing an array via `props`
- Rendering server-side shell markup
- Hydrating with Stimulus to add interactivity (filtering + empty state)

Invocation:

```ruby
<%= shard "filter_list", 
            props: { items: ["Alpha", "Beta", "Gamma", "Delta", "Comet", "Component", "Counter"] }, 
            hydrate: "immediate" %>
```

Rendered shard ERB (`src/shards/filter_list.erb`):

```erb
<div class="filter-list" data-controller="shard-filter-list">
    <label class="filter-list__control">
        <span>Filter:</span>
        <input type="text" data-role="filter-input" placeholder="Type to filter..." />
    </label>
    <ul class="filter-list__items" data-role="items"></ul>
    <p class="filter-list__empty" data-role="empty" style="display:none;">No matches.</p>
</div>
```

Stimulus controller (`src/assets/controllers/shard_filter_list_controller.js`) handles:

- Initial render of all items
- Debounced filtering as you type
- Empty state visibility
- Optional highlighting of matched substring

Try typing `com` or `ta` after the page loads.

---
