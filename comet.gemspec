Gem::Specification.new do |spec|
  spec.name = "comet"
  spec.version = "0.3.0"
  spec.authors = ["Werner Petrick"]

  spec.summary = "A Ruby-based static site generator"
  spec.description = "Comet is a modern static site generator that uses Markdown for content and ERB-like components called 'shards' for reusable UI elements."
  spec.homepage = "https://github.com/wernerpetrick/comet"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/WernerPetrick/comet"
  spec.metadata["changelog_uri"] = "https://github.com/wernerpetrick/comet/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*.rb"] + Dir["exe/*"] + Dir["templates/**/*"] + ["README.md", "LICENSE.txt", "comet.gemspec"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "redcarpet", "~> 3.6"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "listen", "~> 3.8"
  spec.add_dependency "webrick", "~> 1.8"
  spec.add_dependency "rouge", "~> 4.2"
  spec.add_dependency "front_matter_parser", "~> 1.0"
  spec.add_dependency "sassc", "~> 2.4"
  # mini_racer removed (not currently used) to avoid long native build during install

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rubocop", "~> 1.56"
end
