require "./test_helper"
require "../raml/api"

class ExamplesTest < Minitest::Test

  def setup
    @api = load_parser("examples").api as RAML::Api
  end

  def api : RAML::Api
    @api as RAML::Api
  end



  def xtest_resource_type_example
    response = responses("/articles").first
    media_type = response.serializations[response.serializations.keys.first]
    assert_equal Hash{"title" => "Articles"}.to_s, media_type.example.to_s
  end
  
  def xtest_data_type_example
    response = responses("/things").last
    media_type = response.serializations[response.serializations.keys.first]
    assert_equal Hash{"title" => "foo", "foo" => "bar"}.to_json, media_type.example.to_s
  end 
  
end