require "erb"
require "ostruct"

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

    def markdown_files
      Dir.glob(File.join(pages_path, "**", "*.{md,markdown}"))
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
  end
end
