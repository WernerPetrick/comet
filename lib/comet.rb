require_relative "comet/version"
require_relative "comet/cli"
require_relative "comet/project"
require_relative "comet/markdown_processor"
require_relative "comet/shard_processor"
require_relative "comet/build_system"
require_relative "comet/dev_server"
require_relative "comet/hydration_manager"

module Comet
  class Error < StandardError; end

  def self.root
    File.expand_path("..", __dir__)
  end

  def self.version
    VERSION
  end
end
