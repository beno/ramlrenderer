require "./test_helper"
require "../raml/renderer"

class RendererTest < Minitest::Test
  
  def setup
    @renderer = RAML::Renderer.new(load_parser.api)
    @dir = File.expand_path "../site/", __FILE__
  end
  
  def renderer
    @renderer.as(RAML::Renderer)
  end

  def test_write_files
    renderer.write File.join(@dir as String, "myapi.html")
    %w{ myapi.html api.js api.css }.each do |f|
      assert File.exists?(File.join(@dir as String, f))
    end
  end
  
  def test_bundle_file
    renderer.bundle File.join(@dir as String, "bundle.html")
    %w{ bundle.html }.each do |f|
      assert File.exists?(File.join(@dir as String, f))
    end
  end
  
  def test_coffeescript_export
    renderer.write_fixtures File.join(@dir as String, "fixtures.coffee")
    %w{ fixtures.coffee }.each do |f|
      assert File.exists?(File.join(@dir as String, f))
    end
  end
  
  def teardown
    %w{ myapi.html api.js api.css bundle.html }.each do |f|
      file = File.join(@dir as String, f)
      File.delete(file) if File.exists?(file)
    end
  end
  
  
end

