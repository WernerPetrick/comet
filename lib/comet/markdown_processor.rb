require "redcarpet"
require "rouge"
require "rouge/plugins/redcarpet"
require "front_matter_parser"

module Comet
  class MarkdownProcessor
    class CometRenderer < Redcarpet::Render::HTML
      include Rouge::Plugins::Redcarpet

      def initialize(project)
        @project = project
        super({
          filter_html: false,
          no_images: false,
          no_links: false,
          no_styles: false,
          safe_links_only: false,
          with_toc_data: true,
          hard_wrap: false,
          prettify: true
        })
      end

      def block_code(code, language)
        Rouge.highlight(code, language || "text", "html")
      end
    end

    def initialize(project)
      @project = project
      @renderer = CometRenderer.new(project)
      
      @markdown = Redcarpet::Markdown.new(@renderer, {
        autolink: true,
        tables: true,
        fenced_code_blocks: true,
        strikethrough: true,
        superscript: true,
        underline: true,
        highlight: true,
        quote: true,
        footnotes: true
      })
    end

    def process_file(file_path)
      content = File.read(file_path)
      
      # Parse frontmatter
      parsed = FrontMatterParser::Parser.parse_file(file_path)
      frontmatter = parsed.front_matter || {}
      markdown_content = parsed.content

      # Process shard shortcodes in markdown
      shard_processor = ShardProcessor.new(@project)
      processed_markdown = shard_processor.process_shortcodes(markdown_content)

      # Convert markdown to HTML
  html_content = @markdown.render(processed_markdown)
  html_content = post_process_html_for_shards(html_content)

      {
        frontmatter: frontmatter,
        content: html_content,
        raw_content: markdown_content
      }
    end

    def process_content(content, frontmatter = {})
      shard_processor = ShardProcessor.new(@project)
      processed_markdown = shard_processor.process_shortcodes(content)
  html_content = @markdown.render(processed_markdown)
  html_content = post_process_html_for_shards(html_content)

      {
        frontmatter: frontmatter,
        content: html_content,
        raw_content: content
      }
    end
  end
end

module Comet
  class MarkdownProcessor
    # Post HTML pass: process any remaining shard tags not converted in markdown phase,
    # while preserving <pre><code> blocks (already escaped fences).
    def post_process_html_for_shards(html)
      shard_processor = ShardProcessor.new(@project)
      preserves = {}
      # Extract pre/code blocks to avoid transforming examples
      html = html.gsub(/<pre[\s\S]*?<\/pre>/m) do |block|
        key = "__COMET_PRE_BLOCK_#{preserves.size}__"
        preserves[key] = block
        key
      end

      # Now process any shard invocations in remaining HTML
      html = shard_processor.process_shortcodes(html)

      # Restore preserved blocks
      preserves.each { |k, v| html.gsub!(k, v) }
      html
    end
  end
end
