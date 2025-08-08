require "erb"
require "ostruct"
require "front_matter_parser"

module Comet
  class Project
    attr_reader :root_path, :config

    def initialize(root_path)
      @root_path = root_path
      load_config
    end

    def src_path
      File.join(root_path, config.src_dir || "src")
    end

    def pages_path
      File.join(src_path, "pages")
    end

    def shards_path
      File.join(src_path, "shards")
    end

    def public_path
      File.join(root_path, "public")
    end

    def dist_path
      File.join(root_path, config.output_dir || "dist")
    end

    def layouts_path
      File.join(src_path, "layouts")
    end

    def assets_path
      File.join(src_path, "assets")
    end

    # All content markdown files that should become pages (navbar files included; per-file front matter can hide)
    def markdown_files
      Dir.glob(File.join(pages_path, "**", "*.{md,markdown}"))
    end

    # Directory holding markdown files that define navigation links
    def navbar_pages_path
      File.join(pages_path, "navbar")
    end

    # Markdown files inside the navbar folder
    def navbar_markdown_files
      return [] unless Dir.exist?(navbar_pages_path)
      Dir.glob(File.join(navbar_pages_path, "*.{md,markdown}"))
    end

    # Returns an ordered array of navigation entries (links or groups).
    # Link structure: OpenStruct(type: :link, title:, url:, order:, file:)
    # Group structure: OpenStruct(type: :group, title:, order:, children: [links], file: index_file_or_nil)
    def nav_links
      @nav_links ||= build_nav_links
    end

    # Fallback: top-level page links (excluding index) if no explicit navbar entries
    def root_page_nav_links
      Dir.glob(File.join(pages_path, "*.{md,markdown}")).map do |file|
        base = File.basename(file, File.extname(file))
        next if base == "index"
        OpenStruct.new(
          type: :link,
          title: base.tr('_-', ' ').split.map(&:capitalize).join(' '),
          order: 9999,
          url: "/#{base}/",
          file: file
        )
      end.compact
    end

    def shard_files
      Dir.glob(File.join(shards_path, "**", "*.erb"))
    end

    private

  def load_config
      config_file = File.join(root_path, "comet.config.rb")
      if File.exist?(config_file)
        @config = OpenStruct.new(
          src_dir: "src",
          output_dir: "dist",
          site: OpenStruct.new(
            title: "Comet Site",
            description: "A site built with Comet"
          )
        )
        @config.instance_eval(File.read(config_file))
      else
        @config = OpenStruct.new(
          src_dir: "src",
          output_dir: "dist",
          site: OpenStruct.new(
            title: "Comet Site",
            description: "A site built with Comet"
          )
        )
      end
    end

    def parse_front_matter(file)
      FrontMatterParser::Parser.parse_file(file).front_matter
    rescue => _e
      {}
    end

    # Derive the public URL path from a relative path inside pages/
    def derive_url_from_relative(rel_path)
      # Remove extension
      without_ext = rel_path.sub(/\.(md|markdown)$/i, "")
      # Strip leading navbar/ if present
      without_ext = without_ext.sub(/^navbar\//, "")
      parts = without_ext.split("/")
      if parts.last == "index"
        "/" + (parts[0..-2].join("/") + "/").sub(%r{^/+$}, "/")
      else
        "/" + (without_ext == "index" ? "" : without_ext + "/")
      end
    end

    def build_nav_links
      return [] unless Dir.exist?(navbar_pages_path)

      # Root-level markdown files (direct children of navbar_pages_path) excluding index.md variants
      root_links = Dir.glob(File.join(navbar_pages_path, "*.{md,markdown}")).reject { |f| File.basename(f, '.*') == 'index' }
      root_link_structs = root_links.map { |f| nav_link_struct(f) }

      # Group directories (one level deep)
      group_dirs = Dir.glob(File.join(navbar_pages_path, "*"))
                       .select { |d| File.directory?(d) }

      group_structs = group_dirs.map { |dir| nav_group_struct(dir) }.compact

      # Combine and sort
      combined = (root_link_structs + group_structs)
      combined.sort_by { |e| [e.order, e.title] }
    end

    def nav_link_struct(file)
      fm = parse_front_matter(file)
      rel = file.sub(pages_path + "/", "")
      OpenStruct.new(
        type: :link,
        title: fm["title"] || File.basename(file, ".md").sub(/\..*$/, "").tr('_-', ' ').split.map(&:capitalize).join(' '),
        order: (fm["order"] || 9999).to_i,
        url: fm["url"] || derive_url_from_relative(rel),
        file: file
      )
    end

    def nav_group_struct(dir)
      index_file = Dir.glob(File.join(dir, "index.{md,markdown}")).first
      fm = index_file ? parse_front_matter(index_file) : {}
      title = fm["title"] || File.basename(dir).tr('_-', ' ').split.map(&:capitalize).join(' ')
      order = (fm["order"] || 9999).to_i
      # Child links (exclude index.*)
      child_files = Dir.glob(File.join(dir, "*.{md,markdown}")).reject { |f| File.basename(f, '.*') == 'index' }
      children = child_files.map { |f| nav_link_struct(f) }.sort_by { |c| [c.order, c.title] }
      return nil if children.empty? && !index_file # skip empty groups without index metadata
      OpenStruct.new(
        type: :group,
        title: title,
        order: order,
        children: children,
        file: index_file,
        url: fm["url"] # optional if group should be clickable
      )
    end
  end
end
