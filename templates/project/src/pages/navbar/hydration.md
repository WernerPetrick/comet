---
title: Hydration
order: 3
---

# Hydration

Comet supports three hydration strategies for shards:

| Strategy | When it runs |
|----------|--------------|
| immediate | As soon as the hydration script executes |
| load | After DOMContentLoaded (not waiting for all images) |
| visible | When the element scrolls into view |

Pick the lightest strategy that still delivers the UX you need.

### How this works with Stimulus

1. Each hydrated shard wrapper gets `data-controller="shard-<name>"` (or a custom controller if you specify one).
2. The hydration manager triggers `comet:hydrate` on the wrapper when its strategy conditions are met.
3. Your Stimulus controller can react in `connect()` or by listening for the `comet:hydrate` event for deferred logic.

```js
// Example pattern inside a Stimulus controller
connect() {
	this.element.addEventListener('comet:hydrate', e => {
		// safe to run interactive code here
	}, { once: true });
}
```

`visible` uses IntersectionObserver (threshold 0.1). If unsupported, fallback is simply not auto‑hydrated (add a manual call or pick `load`).

### Meta Reminder

Hydration strategy doesn’t affect SEO metadata; add your social preview image in page front matter (`image:`) if needed.

Last updated after Stimulus integration: load = DOMContentLoaded; immediate still earliest; visible unchanged.
