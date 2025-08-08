---
title: Hydration
order: 3
---

# Hydration

Comet supports three hydration strategies for shards:

| Strategy | When it runs |
|----------|--------------|
| immediate | As soon as the hydration script executes |
| load | After the full window load event |
| visible | When the element scrolls into view |

Pick the lightest strategy that still delivers the UX you need.

### Meta Reminder

Hydration strategy doesn’t affect SEO metadata; add your social preview image in page front matter (`image:`) if needed.
