# <%= config[:name] %>

A Comet project.

## Getting Started

```bash
# Start development server
comet dev

# Build for production
comet build
```

## Project Structure

- `src/pages/` - Markdown pages
- `src/shards/` - Reusable components  
- `src/layouts/` - Page layouts
- `src/assets/` - CSS, JavaScript, images
- `public/` - Static files
- `dist/` - Built site (generated)

## Shards

Create reusable components using ERB templates in `src/shards/`:

```erb
<!-- src/shards/button.erb -->
<button class="btn <%= prop(:variant, 'primary') %>" data-action="<%= prop(:action) %>">
  <%= prop(:text, 'Click me') %>
</button>
```

Use in Markdown:

```markdown
<%= shard "button", props: { text: "Sign Up", variant: "primary", action: "signup" }, hydrate: "visible" %>
```

## Hydration Strategies

- `immediate` - Hydrate immediately when script loads
- `load` - Hydrate after DOM content loaded  
- `visible` - Hydrate when element becomes visible

## Assets

CSS and JavaScript files in `src/assets/` are automatically processed and copied to the output directory.
