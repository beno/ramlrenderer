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
    assert ((@api as RAML::Api).spec as Hash)["title"] = "Test API"
  end

  

end