require "./test_helper"
require "../raml/parser"

class ParserTest < Minitest::Test
  
  def setup
    @api = load_parser.api as RAML::Api
  end
  
  def test_types_directive
    assert (@api as RAML::Api).types.has_key? "Article"
  end
  
  def test_title_directive
    assert_equal "Test API", (@api as RAML::Api).spec("title")
  end

  def test_resource
    assert_equal 1, (@api as RAML::Api).resources.size
  end
  
  def test_resource_type_include
    assert (((@api as RAML::Api).spec("resourceTypes") as Hash)["collectionType"] as Hash).has_key? "description"
  end
  
  def test_traits_include
    assert (((@api as RAML::Api).spec("traits") as Hash)["searchable"] as Hash).has_key? "queryParameters"
  end

  
  def test_namespaced_library
    assert (@api as RAML::Api).types.has_key? "Article"
    assert (@api as RAML::Api).types.has_key? "common.Article"
  end

end