require "./test_helper"
require "../raml/parser"

class ParserTest < Minitest::Test
  
  def test_load_file
    assert load_parser.api
  end

end