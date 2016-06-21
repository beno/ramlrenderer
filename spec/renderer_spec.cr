require "./test_helper"
require "../raml/renderer"

class RendererTest < Minitest::Test
  
  def setup
    @renderer = RAML::Renderer.new(load_parser.api)
    @dir = File.expand_path "../site/", __FILE__
  end

  def test_write_files
    (@renderer as RAML::Renderer).write File.join(@dir as String, "myapi.html")
    %w{ myapi.html api.js api.css }.each do |f|
      assert File.exists?(File.join(@dir as String, f))
    end
  end
  
  def teardown
    %w{ myapi.html api.js api.css }.each do |f|
      file = File.join(@dir as String, f)
      File.delete(file) if File.exists?(file)
    end
  end
  
  
end

