require "erb"
require "ostruct"
require "front_matter_parser"
require "date"

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

    # ---------------- Collections System (generalized Option B) ----------------

    def collections
      @collections ||= build_collections
    end

    def collection_definitions
      @collection_definitions ||= (@config.respond_to?(:_collection_definitions) ? @config._collection_definitions : [])
    end

    def tags_index
      @tags_index ||= build_tags_index
    end

    def any_tags?
      tags_index.any?
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
        inject_collections_dsl(@config)
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

    def inject_collections_dsl(cfg)
      cfg.define_singleton_method(:_collection_definitions) { @_collection_definitions ||= [] }
      cfg.define_singleton_method(:collections) do |&block|
        instance_eval(&block) if block
      end
      cfg.define_singleton_method(:collection) do |name, **opts|
        _collection_definitions << OpenStruct.new(name: name.to_sym, options: opts)
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

    # -------- Collections helpers --------

    def build_collections
      collection_definitions.map { |defn| build_collection(defn) }.compact
    end

    def build_collection(defn)
      opts = defn.options
      source = File.join(src_path, opts[:source] || "collections/#{defn.name}")
      return nil unless Dir.exist?(source)
      template = opts[:template] || "pages/#{defn.name}/[slug].md"
      template_path = File.join(src_path, template)
      unless File.exist?(template_path)
        warn "[Comet] Collection :#{defn.name} missing template #{template_path}, skipping"
        return nil
      end
      output_dir = opts[:output_dir] || defn.name.to_s
      permalink = opts[:permalink] # e.g. "/blog/:year/:month/:slug/"
      feed = opts.fetch(:feed, false)
      tags_enabled = opts.fetch(:tags, false)
      items = Dir.glob(File.join(source, "*.{md,markdown}"))
                 .map { |f| build_collection_item(f, defn.name, output_dir, permalink, tags_enabled) }
                 .compact
      # sort
      sort_cfg = opts[:sort]
      items = sort_collection_items(items, sort_cfg)
      OpenStruct.new(
        name: defn.name,
        definition: defn,
        template_path: template_path,
        output_dir: output_dir,
        permalink: permalink,
        feed: feed,
        tags: tags_enabled,
        items: items
      )
    end

    def build_collection_item(file, collection_name, output_dir, permalink, tags_enabled)
      fm = parse_front_matter(file)
      raw = File.read(file)
      content_part = raw.split(/^---\s*$\n?/).last.to_s
      slug = (fm["slug"] || File.basename(file, File.extname(file))).downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      date = begin
        fm["date"] ? Date.parse(fm["date"].to_s) : File.mtime(file).to_date
      rescue
        Date.today
      end
      tags = []
      if tags_enabled
        raw_tags = fm["tags"]
        if raw_tags.is_a?(String)
          tags = raw_tags.split(/[,;]+/)
        elsif raw_tags.is_a?(Array)
          tags = raw_tags
        end
        tags = tags.map { |t| t.to_s.strip }.reject(&:empty?).map { |t| t.downcase }
      end
      excerpt = fm["excerpt"] || begin
        para = content_part.split(/\n\n+/).find { |p| p.strip.length > 20 }
        para ? para.strip.gsub(/\n+/, ' ')[0,220] : nil
      end
      url = if permalink
        build_permalink(permalink, slug, date, output_dir)
      else
        "/#{output_dir}/#{slug}/"
      end
      OpenStruct.new(
        collection: collection_name,
        slug: slug,
        title: fm["title"] || slug.tr('-', ' ').split.map(&:capitalize).join(' '),
        date: date,
        url: url,
        frontmatter: fm,
        excerpt: excerpt,
        tags: tags,
        source_file: file,
        raw_content: content_part
      )
    end

    def sort_collection_items(items, sort_cfg)
      return items.sort_by { |p| [-p.date.to_time.to_i, p.title] } unless sort_cfg
      field = (sort_cfg[:field] || :date).to_sym
      order = (sort_cfg[:order] || :desc).to_sym
      items.sort_by! do |it|
        v = it.send(field) rescue nil
        v.is_a?(Date) ? v.to_time.to_i : v
      end
      items.reverse! if order == :desc
      items
    end

    def build_permalink(pattern, slug, date, output_dir)
      year = date.year
      month = format('%02d', date.month)
      day = format('%02d', date.day)
      pattern.gsub(':year', year.to_s)
             .gsub(':month', month.to_s)
             .gsub(':day', day.to_s)
             .gsub(':slug', slug)
    end

    def build_tags_index
      tag_map = Hash.new { |h,k| h[k] = [] }
      collections.each do |col|
        next unless col&.tags
        col.items.each do |item|
          item.tags.each { |t| tag_map[t] << item }
        end
      end
      # sort items inside each tag by date desc
      tag_map.each { |_, arr| arr.sort_by! { |p| [-p.date.to_time.to_i, p.title] } }
      tag_map
    end
  end
end
