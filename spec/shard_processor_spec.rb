require_relative "../lib/comet"
require "tempfile"
require "tmpdir"

RSpec.describe Comet::ShardProcessor do
  let(:project) do
    project_path = Dir.mktmpdir
    
    # Create basic project structure
    Dir.mkdir(File.join(project_path, "src"))
    Dir.mkdir(File.join(project_path, "src", "shards"))
    
    # Create a simple shard
    File.write(File.join(project_path, "src", "shards", "test-button.erb"), 
      '<button class="<%= prop(:class) %>"><%= prop(:text, "Click me") %></button>')
    
    Comet::Project.new(project_path)
  end
  
  let(:shard_processor) { described_class.new(project) }

  describe "#process_shortcodes" do
    it "processes shard shortcodes correctly" do
      content = 'Hello <%= shard "test-button", props: { text: "Test", class: "btn" } %> world'
      
      result = shard_processor.process_shortcodes(content)
      
      expect(result).to include('<button class="btn">Test</button>')
      expect(result).to include("Hello")
      expect(result).to include("world")
    end

    it "handles shards without props" do
      content = '<%= shard "test-button" %>'
      
      result = shard_processor.process_shortcodes(content)
      
      expect(result).to include('<button class="">Click me</button>')
    end

    it "handles hydration wrapper" do
      content = '<%= shard "test-button", hydrate: "load" %>'
      
      result = shard_processor.process_shortcodes(content)
      
      expect(result).to include('data-shard="test-button"')
      expect(result).to include('data-hydrate="load"')
      expect(result).to include('<script>')
    end
  end

  describe "#render_shard" do
    it "returns error comment for missing shard" do
      result = shard_processor.render_shard("nonexistent-shard")
      
      expect(result).to eq("<!-- Shard 'nonexistent-shard' not found -->")
    end
  end
end
