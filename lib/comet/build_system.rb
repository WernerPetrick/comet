require "fileutils"
require "sassc"
require "cgi"
require "erb"

module Comet
  class BuildSystem
    def initialize(project)
      @project = project
      @markdown_processor = MarkdownProcessor.new(project)
    end

    def build
      puts "🚀 Building Comet project..."
      
      # Clean dist directory
      FileUtils.rm_rf(@project.dist_path)
      FileUtils.mkdir_p(@project.dist_path)

  # Build pages
  build_pages

  # Collections
  build_blog_collection if @project.respond_to?(:blog_template_path) && @project.blog_template_path

      # Copy assets
      copy_assets

      # Copy public files
      copy_public_files

      # Generate hydration script
      generate_hydration_script

      puts "✅ Build complete!"
    end

    private

    def build_pages
      puts "📄 Building pages..."
      
      @project.markdown_files.each do |file_path|
        # Skip dynamic template placeholder for blog collection
        next if File.basename(file_path) == "[slug].md"
        build_page(file_path)
      end
    end

  def build_page(file_path)
      # Get relative path from pages directory
      relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(@project.pages_path))
      # Align physical output path with logical URL by stripping navbar/ prefix like we do for links
      if relative_path.to_s.start_with?("navbar/")
        relative_path = Pathname.new(relative_path.to_s.sub(/^navbar\//, ""))
      end
      
      # Process markdown
      processed = @markdown_processor.process_file(file_path)

      # Respect hidden / nav_only front matter to skip generating a standalone page
      fm = processed[:frontmatter]
      if fm["hidden"] || fm["nav_only"]
        puts "  • (skipped hidden) #{relative_path}"
        return
      end
      
  # Compute public URL for meta tags / canonical (same rules as derive_url)
  page_url = compute_public_url(relative_path.to_s)

  # Apply layout
  html_content = apply_layout(processed, page_url)
      
      # Determine output path
      output_path = get_output_path(relative_path)
      
      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(output_path))
      
      # Write file
      File.write(output_path, html_content)
      
      puts "  ✓ #{relative_path} → #{Pathname.new(output_path).relative_path_from(Pathname.new(@project.dist_path))}"
    end

  def apply_layout(processed_content, page_url)
      layout_name = processed_content[:frontmatter]["layout"] || "default"
      layout_path = File.join(@project.layouts_path, "#{layout_name}.erb")
      
      if File.exist?(layout_path)
        layout_template = ERB.new(File.read(layout_path))
    layout_context = LayoutContext.new(@project, processed_content, page_url)
        layout_template.result(layout_context.get_binding)
      else
        # Default layout if none exists
        default_layout(processed_content)
      end
    end

    def default_layout(processed_content)
      title = processed_content[:frontmatter]["title"] || @project.config.site.title
      
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{title}</title>
          <link rel="stylesheet" href="/assets/styles.css">
        </head>
        <body>
          #{processed_content[:content]}
          <script src="/assets/hydration.js"></script>
        </body>
        </html>
      HTML
    end

    def get_output_path(relative_path)
      # Convert .md files to .html and handle index files
      output_path = relative_path.to_s.gsub(/\.(md|markdown)$/, ".html")
      
      # Handle index files
      if File.basename(output_path, ".html") == "index"
        File.join(@project.dist_path, File.dirname(output_path), "index.html")
      else
        # Create directory structure for clean URLs
        basename = File.basename(output_path, ".html")
        dirname = File.dirname(output_path)
        
        if dirname == "."
          File.join(@project.dist_path, basename, "index.html")
        else
          File.join(@project.dist_path, dirname, basename, "index.html")
        end
      end
    end

    def copy_assets
      return unless Dir.exist?(@project.assets_path)
      
      puts "📦 Copying assets..."
      
      assets_dist_path = File.join(@project.dist_path, "assets")
      FileUtils.mkdir_p(assets_dist_path)

      Dir.glob(File.join(@project.assets_path, "**", "*")).each do |asset_path|
        next if File.directory?(asset_path)
        
        relative_path = Pathname.new(asset_path).relative_path_from(Pathname.new(@project.assets_path))
        output_path = File.join(assets_dist_path, relative_path)
        
        FileUtils.mkdir_p(File.dirname(output_path))
        
        if asset_path.end_with?(".scss", ".sass")
          # Compile Sass/SCSS
          compile_scss(asset_path, output_path.gsub(/\.(scss|sass)$/, ".css"))
        else
          FileUtils.cp(asset_path, output_path)
        end
        
        puts "  ✓ assets/#{relative_path}"
      end
    end

    def compile_scss(input_path, output_path)
      sass_content = File.read(input_path)
      engine_opts = {
        syntax: input_path.end_with?(".sass") ? :sass : :scss,
        style: :compressed,
        load_paths: [
          File.dirname(input_path),
          File.expand_path("../../templates/shared", __dir__) # allow resolving comet_base.scss directly from gem
        ].select { |p| Dir.exist?(p) }
      }

      begin
        compiled_css = SassC::Engine.new(sass_content, engine_opts).render
        File.write(output_path, compiled_css)
      rescue SassC::SyntaxError => e
        if e.message.include?("comet_base")
          # Attempt automatic recovery: if import exists but file missing, inject base partial
          assets_dir = File.dirname(input_path)
          base_partial = File.join(assets_dir, "_comet_base.scss")
          template_base = File.expand_path("../../templates/shared/comet_base.scss", __dir__)
          if !File.exist?(base_partial) && File.exist?(template_base)
            FileUtils.cp(template_base, base_partial)
            puts "⚠️  Missing _comet_base.scss detected – injected from templates and retrying."
            begin
              compiled_css = SassC::Engine.new(sass_content, engine_opts).render
              File.write(output_path, compiled_css)
              return
            rescue SassC::SyntaxError
              # Fall through to fallback removal
            end
          end
          if sass_content.include?("@import 'comet_base'") || sass_content.include?("@import \"comet_base\"")
            puts "⚠️  Could not resolve @import 'comet_base'; compiling without it (create _comet_base.scss to enable base styles)."
            stripped = sass_content.lines.reject { |l| l.include?("@import 'comet_base'") || l.include?("@import \"comet_base\"") }.join
            compiled_css = SassC::Engine.new(stripped, engine_opts).render
            File.write(output_path, compiled_css)
            return
          end
        end
        raise # re-raise if unrelated or unrecoverable
      end
    end

    def copy_public_files
      return unless Dir.exist?(@project.public_path)
      
      puts "📁 Copying public files..."
      
      Dir.glob(File.join(@project.public_path, "**", "*")).each do |public_file|
        next if File.directory?(public_file)
        
        relative_path = Pathname.new(public_file).relative_path_from(Pathname.new(@project.public_path))
        output_path = File.join(@project.dist_path, relative_path)
        
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp(public_file, output_path)
        
        puts "  ✓ #{relative_path}"
      end
    end

    def generate_hydration_script
      hydration_script = File.join(@project.dist_path, "assets", "hydration.js")
      FileUtils.mkdir_p(File.dirname(hydration_script))
      
      script_content = HydrationManager.generate_client_script
      File.write(hydration_script, script_content)
      
      puts "  ✓ Generated hydration script"
    end

    class LayoutContext
      def initialize(project, processed_content, page_url)
        @project = project
        @content = processed_content[:content]
        @frontmatter = processed_content[:frontmatter]
        @page_url = page_url
      end

      def content
        @content
      end

      def title
        @frontmatter["title"] || @project.config.site.title
      end

      def description
        @frontmatter["description"] || @project.config.site.description
      end

      def frontmatter
        @frontmatter
      end

      def site
        @project.config.site
      end

      # Navigation links (array of OpenStruct: title, url)
      def nav_links
        @project.nav_links
      end

      def fallback_nav_links
        return [] if @project.nav_links.any?
        @project.root_page_nav_links
      end

      def asset_path(path)
        "/assets/#{path}"
      end

      def current_url
        @page_url
      end

      def canonical_url
        base = site.respond_to?(:url) && site.url ? site.url.sub(/\/$/, '') : nil
        return current_url unless base
        base + current_url
      end

      def meta_tags
        title_val = title
        desc_val = description.to_s.strip
        desc_val = desc_val[0,197] + '…' if desc_val.length > 198
        image_val = frontmatter["image"] || frontmatter["og_image"] || (site.respond_to?(:og_image) && site.og_image)
        twitter_handle = site.respond_to?(:twitter) ? site.twitter : nil

        esc = ->(v){ CGI.escapeHTML(v.to_s) }
        tags = []
        # Basic
        tags << %(<meta name="description" content="#{esc.call(desc_val)}">)
        # OpenGraph
        tags << %(<meta property="og:title" content="#{esc.call(title_val)}">)
        tags << %(<meta property="og:description" content="#{esc.call(desc_val)}">)
        tags << %(<meta property="og:site_name" content="#{esc.call(site.title)}">)
        tags << %(<meta property="og:type" content="website">)
        tags << %(<meta property="og:url" content="#{esc.call(canonical_url)}">)
        tags << %(<meta property="og:image" content="#{esc.call(resolve_image_url(image_val))}">) if image_val
        # Twitter
        tags << %(<meta name="twitter:card" content="summary_large_image">)
        tags << %(<meta name="twitter:title" content="#{esc.call(title_val)}">)
        tags << %(<meta name="twitter:description" content="#{esc.call(desc_val)}">)
        tags << %(<meta name="twitter:image" content="#{esc.call(resolve_image_url(image_val))}">) if image_val
        tags << %(<meta name="twitter:site" content="#{esc.call(twitter_handle)}">) if twitter_handle
        tags.join("\n    ")
      end

      def resolve_image_url(raw)
        return nil unless raw
        return raw if raw.start_with?('http://', 'https://', 'data:')
        # Ensure leading slash
        path = raw.start_with?('/') ? raw : "/#{raw}"
        base = site.respond_to?(:url) && site.url ? site.url.sub(/\/$/, '') : nil
        return path unless base
        base + path
      end

      def get_binding
        binding
      end

      # Collection helpers exposed to layouts & templates
      def blog_posts
        return [] unless @project.respond_to?(:blog_posts)
        @project.blog_posts
      end
    end

    def compute_public_url(rel_path)
      base = rel_path.sub(/\.(md|markdown)$/i, '')
      parts = base.split('/')
      if parts.last == 'index'
        '/' + (parts[0..-2].join('/') + '/').sub(%r{^/+$}, '/')
      else
        '/' + (base == 'index' ? '' : base + '/')
      end

      # ---- Collection builders ----
      def build_blog_collection
        puts "📝 Building blog posts..."
        template_path = @project.blog_template_path
        template_fm = FrontMatterParser::Parser.parse_file(template_path).front_matter rescue {}
        raw = File.read(template_path)
        parts = raw.split(/^---\s*$\n?/)
        template_body = parts.length > 2 ? parts[2..].join : parts.first
        @project.blog_posts.each do |post|
          html = render_blog_post(post, template_fm, template_body)
          output_path = get_output_path(Pathname.new("blog/#{post.slug}.md"))
          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, html)
          puts "  ✓ blog/#{post.slug} → #{Pathname.new(output_path).relative_path_from(Pathname.new(@project.dist_path))}"
        end
      end

      def render_blog_post(post, template_fm, template_body)
        merged_fm = template_fm.merge(post.frontmatter || {})
        merged_fm["title"] ||= post.title
        merged_fm["description"] ||= post.excerpt
        body = template_body.dup
        replacements = {
          "{{content}}" => File.read(post.source_file).split(/^---\s*$\n?/).last.to_s,
          "{{title}}" => post.title.to_s,
          "{{date}}" => post.date.to_s,
          "{{slug}}" => post.slug.to_s,
          "{{excerpt}}" => (post.excerpt || '').to_s
        }
        replacements.each { |k,v| body.gsub!(k, v) }
        processed = @markdown_processor.process_content(body, merged_fm)
        page_url = "/blog/#{post.slug}/"
        apply_layout(processed, page_url)
      end
    end
  end
end
