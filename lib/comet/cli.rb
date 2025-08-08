require "thor"
require "fileutils"

module Comet
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), "..", "..", "templates")
    end

    desc "new PROJECT_NAME", "Create a new Comet project"
    option :css, aliases: "-c", type: :string, default: "bulma", 
           desc: "CSS framework to use (bulma, bootstrap, tailwind, custom)"
    def new(project_name)
      css_framework = options[:css].downcase
      
      unless %w[bulma bootstrap tailwind custom].include?(css_framework)
        say "Error: Unsupported CSS framework '#{css_framework}'. Supported: bulma, bootstrap, tailwind, custom", :red
        exit 1
      end
      
      # Prevent creating inside an existing non-empty directory (would nest paths)
      if Dir.exist?(project_name) && !(Dir.children(project_name) - %w[. ..]).empty?
        say "Error: Directory '#{project_name}' already exists and is not empty.", :red
        say "Choose a different project name or remove the existing directory.", :yellow
        exit 1
      end

      say "Creating new Comet project: #{project_name} with #{css_framework.capitalize} CSS", :green
      
      # Set Thor's destination root so all file operations are relative
      self.destination_root = File.expand_path(project_name, Dir.pwd)
      
      # Copy base template files
      directory("project", ".")
      
      # Copy CSS framework specific files
      copy_css_framework_files(css_framework)
      
      # Process template files that need variable substitution
      template_vars = { name: project_name, css_framework: css_framework }
      
      files_to_process = [
        "comet.config.rb",
        "README.md", 
        "src/pages/index.md"
      ]
      
      files_to_process.each do |relative_path|
        full_path = File.join(destination_root, relative_path)
        next unless File.exist?(full_path)
        content = File.read(full_path)
        processed_content = content.gsub("<%= config[:name] %>", project_name)
        File.write(full_path, processed_content)
      end

      inside(destination_root) { run "bundle install" }
      
      say "Project created successfully!", :green
      say "CSS Framework: #{css_framework.capitalize}", :blue
      say "Run 'cd #{project_name} && comet dev' to start development server", :blue
    end

    desc "build", "Build the project for production"
    def build
      ensure_comet_project!
      
      say "Building project...", :green
      project = Comet::Project.new(Dir.pwd)
      build_system = Comet::BuildSystem.new(project)
      build_system.build
      
      say "Build completed! Check the 'dist' directory.", :green
    end

    desc "dev", "Start development server"
    option :port, aliases: "-p", type: :numeric, default: 3000
    def dev
      ensure_comet_project!
      
      say "Starting development server on port #{options[:port]}...", :green
      project = Comet::Project.new(Dir.pwd)
      dev_server = Comet::DevServer.new(project, options[:port])
      dev_server.start
    end

    desc "version", "Show Comet version"
    def version
      say "Comet v#{Comet::VERSION}", :blue
      say "Available CSS frameworks: bulma (default), bootstrap, tailwind, custom", :green
    end

    private

    def copy_css_framework_files(framework)
      # Remove default assets that will be replaced (paths now relative to destination_root)
      FileUtils.rm_f(File.join(destination_root, "src/assets/styles.scss"))
      FileUtils.rm_f(File.join(destination_root, "src/assets/app.js"))

      case framework
      when "bulma"
        copy_file("css_frameworks/bulma/styles.scss", "src/assets/styles.scss")
        copy_file("css_frameworks/bulma/app.js", "src/assets/app.js")
        # Bulma-specific shards
        directory("css_frameworks/bulma/shards", "src/shards") if File.exist?(File.join(self.class.source_root, "css_frameworks/bulma/shards"))
      when "bootstrap"
        copy_file("css_frameworks/bootstrap/styles.scss", "src/assets/styles.scss")
        copy_file("css_frameworks/bootstrap/app.js", "src/assets/app.js")
      when "tailwind"
        copy_file("css_frameworks/tailwind/styles.css", "src/assets/styles.css")
        copy_file("css_frameworks/tailwind/tailwind.config.js", "tailwind.config.js")
        copy_file("css_frameworks/tailwind/app.js", "src/assets/app.js")
      when "custom"
        copy_file("css_frameworks/custom/styles.scss", "src/assets/styles.scss")
        copy_file("css_frameworks/custom/app.js", "src/assets/app.js")
      end
    end

    def ensure_comet_project!
      unless File.exist?("comet.config.rb")
        say "Error: Not a Comet project. Run 'comet new PROJECT_NAME' to create one.", :red
        exit 1
      end
    end
  end
end
