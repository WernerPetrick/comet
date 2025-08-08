# Comet Configuration

# Site metadata
site.title = "<%= config[:name] %>"
site.description = "A site built with Comet"

collections do
	collection :blog,
		# Using the default source (src/collections/blog) so source: is omitted
		template: "pages/blog/[slug].md",   # dynamic item template
		output_dir: "blog",                 # output base path
		permalink: "/blog/:year/:month/:slug/", # dated permalink structure
		sort: { field: :date, order: :desc },     # newest first
		feed: true,                         # emit /blog/feed.json
		tags: true                          # extract tags & build /tags pages
end

# To add another collection:
# collections do
#   collection :notes,
#     template: "pages/notes/[slug].md",
#     tags: false,
#     feed: false
# end

# Optional extended metadata for social sharing / SEO
# site.url = "https://example.com"          # Used for absolute canonical / og:url
# site.twitter = "@yourhandle"              # Twitter handle (with @)
# site.og_image = "/assets/og-default.png"  # Default OpenGraph image (1200x630 recommended)
# To change per-page, add `image:` (or `og_image:`) in that page's front matter. `image` takes precedence.

# Build configuration
# src_dir = "src"        # Source directory (default: "src")
# output_dir = "dist"    # Output directory (default: "dist")
