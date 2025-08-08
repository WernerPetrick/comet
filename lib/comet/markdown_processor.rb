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

      {
        frontmatter: frontmatter,
        content: html_content,
        raw_content: content
      }
    end
  end
end
