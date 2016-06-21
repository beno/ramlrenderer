require "minitest/autorun"

module TestHelper
    
  def load_parser
    RAML::Parser.new(File.expand_path("../fixtures/test.raml", __FILE__)) as RAML::Parser
  end
  
end

include TestHelper
  