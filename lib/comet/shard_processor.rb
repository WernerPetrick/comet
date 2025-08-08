require "erb"
require "json"

module Comet
  class ShardProcessor
    SHARD_PATTERN = /<%=\s*shard\s+"([^"]+)"(?:\s*,\s*(.+?))?\s*%>/m

    def initialize(project)
      @project = project
      @shard_cache = {}
    end

    def process_shortcodes(content)
      content.gsub(SHARD_PATTERN) do |match|
        shard_name = $1
        options_str = $2

        # Parse options
        options = parse_shard_options(options_str)
        
        # Render the shard
        render_shard(shard_name, options)
      end
    end

    def render_shard(shard_name, options = {})
      shard_path = find_shard_file(shard_name)
      
      unless shard_path
        return "<!-- Shard '#{shard_name}' not found -->"
      end

      # Load and cache shard template
      shard_template = load_shard_template(shard_path)
      
      # Prepare context for ERB rendering
      context = ShardContext.new(@project, options)
      
      # Render the shard
      begin
        result = shard_template.result(context.get_binding)
        
        # Add hydration wrapper if needed
        if options[:hydrate]
          wrap_with_hydration(result, shard_name, options)
        else
          result
        end
      rescue => e
        "<!-- Error rendering shard '#{shard_name}': #{e.message} -->"
      end
    end

    private

    def parse_shard_options(options_str)
      return {} unless options_str

      # Simple parser for Ruby hash-like syntax
      # This is a simplified version - you might want to use a proper parser
      options = {}
      
      # Extract props
      if options_str.match(/props:\s*\{([^}]+)\}/)
        props_str = $1
        props = {}
        props_str.scan(/(\w+):\s*"([^"]*)"/) do |key, value|
          props[key.to_sym] = value
        end
        options[:props] = props
      end

      # Extract hydrate
      if options_str.match(/hydrate:\s*"([^"]*)"/)
        options[:hydrate] = $1
      end

      # Extract other options
      options_str.scan(/(\w+):\s*"([^"]*)"/) do |key, value|
        next if key == "props" # Already handled
        options[key.to_sym] = value
      end

      options
    end

    def find_shard_file(shard_name)
      # Try different possible locations
      possible_paths = [
        File.join(@project.shards_path, "#{shard_name}.erb"),
        File.join(@project.shards_path, shard_name, "index.erb"),
        File.join(@project.shards_path, shard_name, "#{shard_name}.erb")
      ]

      possible_paths.find { |path| File.exist?(path) }
    end

    def load_shard_template(shard_path)
      # Cache templates for performance
      @shard_cache[shard_path] ||= begin
        template_content = File.read(shard_path)
        ERB.new(template_content, trim_mode: "-")
      end
    end

    def wrap_with_hydration(content, shard_name, options)
      hydration_id = "shard-#{shard_name}-#{rand(10000)}"
      hydration_strategy = options[:hydrate] || "load"
      
      props_json = options[:props] ? options[:props].to_json : "{}"
      
      <<~HTML
        <div id="#{hydration_id}" 
             data-shard="#{shard_name}" 
             data-hydrate="#{hydration_strategy}"
             data-props='#{props_json}'>
          #{content}
        </div>
        <script>
          window.__COMET_SHARDS__ = window.__COMET_SHARDS__ || [];
          window.__COMET_SHARDS__.push({
            id: "#{hydration_id}",
            name: "#{shard_name}",
            strategy: "#{hydration_strategy}",
            props: #{props_json}
          });
        </script>
      HTML
    end

    class ShardContext
      def initialize(project, options = {})
        @project = project
        @props = options[:props] || {}
        @hydrate = options[:hydrate]
      end

      def props
        @props
      end

      def prop(key, default = nil)
        @props[key.to_sym] || @props[key.to_s] || default
      end

      def hydrate?
        !@hydrate.nil?
      end

      def hydration_strategy
        @hydrate
      end

      def get_binding
        binding
      end

      # Helper methods available in shards
      def partial(name, locals = {})
        # Load partial from shards directory
        partial_path = File.join(@project.shards_path, "_#{name}.erb")
        if File.exist?(partial_path)
          template = ERB.new(File.read(partial_path))
          context = PartialContext.new(locals)
          template.result(context.get_binding)
        else
          "<!-- Partial '#{name}' not found -->"
        end
      end

      def asset_path(path)
        "/assets/#{path}"
      end

      def site
        @project.config.site
      end
    end

    class PartialContext
      def initialize(locals = {})
        locals.each do |key, value|
          instance_variable_set("@#{key}", value)
          define_singleton_method(key) { value }
        end
      end

      def get_binding
        binding
      end
    end
  end
end
