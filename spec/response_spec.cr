require "./test_helper"
require "../raml/parser"
require "../raml/api"

class ResponseTest < Minitest::Test

  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def api : RAML::Api
    @api as RAML::Api
  end
  
  def responses(url)
    api.all_resources[url].requests.first.responses
  end
  
      
  def test_response_data_type_string
    response = responses("/things").first
    media_type = response.media_types[response.media_types.keys.first]
    assert media_type.data_type
    assert media_type.data_type.properties.has_key? "title"
    refute media_type.data_type.properties.has_key? "foo"
  end
  
  def test_response_data_type_hash
    response = responses("/things").last
    media_type = response.media_types[response.media_types.keys.first]
    assert media_type.data_type
    assert media_type.data_type.properties.has_key? "title"
    assert media_type.data_type.properties.has_key? "foo"
  end
  
  
  def test_interpolate_resourcePath_type
    response = responses("/articles").first
    assert_equal 1, response.media_types.size
    response.media_types.each do |_, media_type|
      assert_equal "Article", media_type.data_type.name
      assert media_type.data_type.properties.has_key? "title"
    end
  end
  
  def test_resource_type_example
    response = responses("/articles").first
    media_type = response.media_types[response.media_types.keys.first]
    assert_equal Hash{"title" => "Articles"}.to_s, media_type.example.to_s
  end
  
  def test_data_type_example
    response = responses("/things").last
    media_type = response.media_types[response.media_types.keys.first]
    assert_equal Hash{"title" => "foo", "foo" => "bar"}.to_s, media_type.example.to_s
  end 
    
end