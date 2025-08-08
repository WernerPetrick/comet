---
layout: default
title: "Blog Post"
description: "Generic blog post template"
---

# {{title}}

_Published: {{date}}_

{{content}}

---

### More Posts

<ul>
<% blog_posts.each do |p| %>
  <% next if p.slug == "{{slug}}" %>
  <li><a href="<%= p.url %>"><%= p.title %></a></li>
<% end %>
</ul>
