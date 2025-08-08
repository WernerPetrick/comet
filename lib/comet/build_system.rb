require "fileutils"
require "sassc"

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
      
      # Apply layout
      html_content = apply_layout(processed)
      
      # Determine output path
      output_path = get_output_path(relative_path)
      
      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(output_path))
      
      # Write file
      File.write(output_path, html_content)
      
      puts "  ✓ #{relative_path} → #{Pathname.new(output_path).relative_path_from(Pathname.new(@project.dist_path))}"
    end

    def apply_layout(processed_content)
      layout_name = processed_content[:frontmatter]["layout"] || "default"
      layout_path = File.join(@project.layouts_path, "#{layout_name}.erb")
      
      if File.exist?(layout_path)
        layout_template = ERB.new(File.read(layout_path))
        layout_context = LayoutContext.new(@project, processed_content)
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
      def initialize(project, processed_content)
        @project = project
        @content = processed_content[:content]
        @frontmatter = processed_content[:frontmatter]
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

      def get_binding
        binding
      end
    end
  end
end
