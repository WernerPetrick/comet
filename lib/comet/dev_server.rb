require "webrick"
require "listen"
require "json"

module Comet
  class DevServer
    def initialize(project, port = 3000)
      @project = project
      @port = port
      @build_system = BuildSystem.new(project)
    end

    def start
      # Initial build
      @build_system.build

      # Start file watcher
      start_file_watcher

      # Start web server
      start_web_server
    end

    private

    def start_file_watcher
      puts "👀 Watching for file changes..."
      
      watch_dirs = [@project.src_path]
      watch_dirs << @project.public_path if Dir.exist?(@project.public_path)
      
      @listener = Listen.to(*watch_dirs) do |modified, added, removed|
        handle_file_changes(modified, added, removed)
      end
      
      @listener.start
    end

    def handle_file_changes(modified, added, removed)
      changed_files = (modified + added + removed).uniq
      
      puts "\n🔄 Files changed:"
      changed_files.each { |file| puts "  • #{file}" }
      
      puts "🔨 Rebuilding..."
      @build_system.build
      puts "✅ Rebuild complete!\n"
    end

    def start_web_server
      puts "🌐 Starting development server on http://localhost:#{@port}"
      
      server = WEBrick::HTTPServer.new(
        Port: @port,
        DocumentRoot: @project.dist_path,
        Logger: WEBrick::Log.new(nil, WEBrick::Log::WARN),
        AccessLog: []
      )

      # Add middleware for development features
      server.mount_proc("/") do |req, res|
        handle_request(req, res)
      end

      # Handle shutdown gracefully
      trap("INT") do
        puts "\n👋 Shutting down development server..."
        @listener&.stop
        server.shutdown
      end

      server.start
    end

    def handle_request(req, res)
      path = req.path
      
      # Handle clean URLs
      if path == "/"
        path = "/index.html"
      elsif path.end_with?("/")
        path = "#{path}index.html"
      elsif !path.include?(".") && !path.end_with?("/")
        path = "#{path}/index.html"
      end

      full_path = File.join(@project.dist_path, path.sub(/^\//, ''))
      
      if File.exist?(full_path) && !File.directory?(full_path)
        # Serve the file
        res.body = File.read(full_path)
        res.content_type = get_content_type(full_path)
        
        # Add development headers
        res["Cache-Control"] = "no-cache, no-store, must-revalidate"
        res["Pragma"] = "no-cache"
        res["Expires"] = "0"
        
        # Inject live reload script for HTML files
        if full_path.end_with?(".html")
          res.body = inject_live_reload_script(res.body)
        end
      else
        # Try to serve index.html for client-side routing
        index_path = File.join(@project.dist_path, "index.html")
        if File.exist?(index_path)
          res.body = File.read(index_path)
          res.content_type = "text/html"
          res.body = inject_live_reload_script(res.body)
        else
          res.status = 404
          res.body = "404 - Page not found"
          res.content_type = "text/plain"
        end
      end
    end

    def get_content_type(file_path)
      case File.extname(file_path).downcase
      when ".html", ".htm"
        "text/html"
      when ".css"
        "text/css"
      when ".js"
        "application/javascript"
      when ".json"
        "application/json"
      when ".png"
        "image/png"
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".gif"
        "image/gif"
      when ".svg"
        "image/svg+xml"
      when ".ico"
        "image/x-icon"
      else
        "application/octet-stream"
      end
    end

    def inject_live_reload_script(html_content)
      live_reload_script = <<~SCRIPT
        <script>
          // Simple live reload implementation
          (function() {
            let lastModified = null;
            
            function checkForChanges() {
              fetch(window.location.href, { cache: 'no-cache' })
                .then(response => {
                  const modified = response.headers.get('last-modified');
                  if (lastModified && modified !== lastModified) {
                    console.log('🔄 Reloading page due to changes...');
                    window.location.reload();
                  }
                  lastModified = modified;
                })
                .catch(() => {
                  // Ignore errors
                });
            }
            
            // Check for changes every 1 second
            setInterval(checkForChanges, 1000);
          })();
        </script>
      SCRIPT

      # Inject before closing body tag
      html_content.gsub("</body>", "#{live_reload_script}</body>")
    end
  end
end
