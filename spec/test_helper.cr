require "minitest/autorun"
require "../raml/parser"

module TestHelper
    
  def load_parser(file = "test")
    RAML::Parser.new(File.expand_path("../fixtures/#{file}.raml", __FILE__)) as RAML::Parser
  end
  
end

include TestHelper
  