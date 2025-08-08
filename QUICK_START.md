# Comet Framework - Quick Start Guide

## 1. Installation

```bash
# Clone the repository
git clone https://github.com/wernerpetrick/comet
cd comet

# Install dependencies
bundle install

# Make CLI executable
chmod +x exe/comet
```

## 2. Create Your First Project

```bash
# Create a new Comet project
./exe/comet new my-blog
cd my-blog
```

## 3. Project Structure

```
my-blog/
├── src/
│   ├── pages/          # Markdown pages (becomes URLs)
│   │   ├── index.md    # Homepage (/)
│   │   └── about.md    # About page (/about)
│   ├── shards/         # Reusable components
│   │   ├── button.erb
│   │   └── card.erb
│   ├── layouts/        # Page layouts
│   │   └── default.erb
│   └── assets/         # CSS, JS, images
│       ├── styles.scss
│       └── app.js
├── public/             # Static files (copied as-is)
├── dist/               # Built site (generated)
├── comet.config.rb     # Configuration
└── Gemfile
```

## 4. Writing Content

Create Markdown files in `src/pages/`:

```markdown
---
title: "My Blog Post"
layout: default
description: "A great blog post"
---

# My Blog Post

This is written in **Markdown** with full support for:

- Lists
- Links
- Code blocks
- And **shards**!

<%= shard "button", props: { text: "Read More", variant: "primary" }, hydrate: "visible" %>
```

## 5. Creating Shards (Components)

Shards are ERB templates in `src/shards/`:

```erb
<!-- src/shards/blog-card.erb -->
<article class="blog-card">
  <% if prop(:image) %>
    <img src="<%= asset_path(prop(:image)) %>" alt="<%= prop(:title) %>">
  <% end %>
  
  <div class="card-content">
    <h3><%= prop(:title) %></h3>
    <p><%= prop(:excerpt) %></p>
    
    <div class="card-meta">
      <span class="date"><%= prop(:date) %></span>
      <a href="<%= prop(:link) %>" class="read-more">Read More</a>
    </div>
  </div>
</article>

<% if hydrate? %>
<style>
  .blog-card {
    border: 1px solid #eee;
    border-radius: 8px;
    overflow: hidden;
    transition: transform 0.2s;
  }
  
  .blog-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  }
</style>
<% end %>
```

Use in Markdown:

```markdown
<%= shard "blog-card", props: {
  title: "Building with Comet",
  excerpt: "Learn how to build static sites with Ruby",
  date: "2025-08-07",
  image: "blog-hero.jpg",
  link: "/posts/building-with-comet"
}, hydrate: "visible" %>
```

## 6. Hydration Strategies

Control when components become interactive:

```markdown
<!-- Hydrate immediately when page loads -->
<%= shard "critical-ui", hydrate: "immediate" %>

<!-- Hydrate after DOM is ready -->
<%= shard "interactive-form", hydrate: "load" %>

<!-- Hydrate when element becomes visible -->
<%= shard "analytics-widget", hydrate: "visible" %>

<!-- Server-side only (no JavaScript) -->
<%= shard "static-content" %>
```

## 7. Client-Side Interactivity

Add JavaScript actions in `src/assets/app.js`:

```javascript
// Define global actions
window.CometActions = {
  // Handle newsletter signup
  newsletter: (event, props) => {
    event.preventDefault();
    const form = event.target;
    const email = form.querySelector('input[name="email"]').value;
    
    fetch('/api/newsletter', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    })
    .then(response => response.json())
    .then(data => {
      alert('Thanks for subscribing!');
    });
  },
  
  // Toggle theme
  toggleTheme: () => {
    document.body.classList.toggle('dark-theme');
  }
};

// Custom hydration for specific shards
window.hydrate_my_widget = function(element, props) {
  // Custom initialization logic
  console.log('Hydrating widget with props:', props);
};
```

Use actions in shards:

```erb
<form data-action="newsletter">
  <input type="email" name="email" required>
  <button type="submit">Subscribe</button>
</form>

<button data-action="toggleTheme">🌙 Toggle Theme</button>
```

## 8. Development Workflow

```bash
# Start development server with hot reload
comet dev

# Build for production
comet build

# The built site is in the 'dist' directory
```

## 9. Advanced Features

### Custom Layouts

```erb
<!-- src/layouts/blog.erb -->
<!DOCTYPE html>
<html>
<head>
  <title><%= title %> | My Blog</title>
  <meta name="description" content="<%= description %>">
  <!-- SEO, fonts, etc. -->
</head>
<body class="blog-layout">
  <header>
    <%= partial("navigation") %>
  </header>
  
  <main>
    <%= content %>
  </main>
  
  <footer>
    <%= partial("footer") %>
  </footer>
  
  <script src="<%= asset_path('hydration.js') %>"></script>
</body>
</html>
```

### Partials

```erb
<!-- src/shards/_navigation.erb -->
<nav class="nav">
  <a href="/" class="logo"><%= site.title %></a>
  <div class="nav-links">
    <a href="/">Home</a>
    <a href="/about">About</a>
    <a href="/blog">Blog</a>
  </div>
</nav>
```

Use partials in layouts or shards:

```erb
<%= partial("navigation") %>
<%= partial("hero", { title: "Welcome!" }) %>
```

### Configuration

```ruby
# comet.config.rb
site.title = "My Awesome Blog"
site.description = "Thoughts on code and life"
site.author = "Your Name"
site.url = "https://myblog.com"

# Custom config
site.social = {
  twitter: "@username",
  github: "username"
}

# Build settings
src_dir = "src"
output_dir = "dist"
```

Access in templates:

```erb
<h1><%= site.title %></h1>
<a href="https://twitter.com/<%= site.social[:twitter] %>">Follow me</a>
```

## 10. Deployment

The `dist` directory contains your built site - deploy it anywhere:

```bash
# Deploy to Netlify (example)
npm install -g netlify-cli
netlify deploy --prod --dir=dist

# Deploy to GitHub Pages
# Push the dist directory to gh-pages branch

# Deploy to any static host
# Upload the contents of 'dist' directory
```

That's it! You now have a powerful static site generator with component-based architecture and selective hydration. Happy building! 🚀
