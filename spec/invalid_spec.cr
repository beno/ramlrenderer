require "./test_helper"
require "../raml/parser"
require "../raml/api"

class InvalidTest < Minitest::Test
  
  def test_invalid
    assert_raises RAML::ParseException do
      load_parser("invalid").api as RAML::Api
    end
  end

end
