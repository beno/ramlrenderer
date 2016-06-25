require "./test_helper"
require "../raml/shared"

class Interpolator
  include RAML::CommonMethods
  include RAML::ResourceTypeTraitsMethods

  property :url
  
  def initialize
    @url = "/articles"
    @spec = Hash(YAML::Type, YAML::Type).new
  end
  
  def interpolate(s)
    interpolate_variables(s)
  end
  
end


class SharedTest < Minitest::Test
  
  def setup
    @intp = Interpolator.new
  end
  
  def intp
    @intp as Interpolator
  end
    
  def test_interpolate
    assert_equal "article", intp.interpolate "<<resourcePathName | !singularize>>"
  end

  def test_interpolate_2
    intp.url = "/article"
    assert_equal "article", intp.interpolate "<<resourcePathName | !singularize>>"
  end
  
  def test_interpolate_3
    intp.url = "/article"
    assert_equal "articles", intp.interpolate "<<resourcePathName | !pluralize>>"
  end
  
  def test_interpolate_4
    intp.url = "/foo_bar"
    assert_equal "fooBar", intp.interpolate "<<resourcePathName | !lowercamelcase>>"
  end

  def test_interpolate_5
    intp.url = "/foo_bar"
    assert_equal "FooBar", intp.interpolate "<<resourcePathName | !uppercamelcase>>"
  end

  def test_interpolate_6
    intp.url = "/foobar"
    assert_equal "FOOBAR", intp.interpolate "<<resourcePathName | !uppercase>>"
  end

  def test_interpolate_7
    intp.url = "/fooBar"
    assert_equal "foobar", intp.interpolate "<<resourcePathName | !lowercase>>"
  end

  def test_interpolate_8
    intp.url = "/foo_bar"
    assert_equal "fooBar", intp.interpolate "<<resourcePathName | !lowercamelcase>>"
  end

  def test_interpolate_9
    intp.url = "/fooBar"
    assert_equal "foo_bar", intp.interpolate "<<resourcePathName | !lowerunderscorecase>>"
  end

  def test_interpolate_10
    intp.url = "/fooBar"
    assert_equal "FOO_BAR", intp.interpolate "<<resourcePathName | !upperunderscorecase>>"
  end
  def test_interpolate_11
    intp.url = "/fooBar"
    assert_equal "foo-bar", intp.interpolate "<<resourcePathName | !lowerhyphencase>>"
  end
  def test_interpolate_12
    intp.url = "/fooBar"
    assert_equal "FOO-BAR", intp.interpolate "<<resourcePathName | !upperhyphencase>>"
  end


end
