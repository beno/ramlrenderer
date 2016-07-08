require "minitest/autorun"

module Foo
  class BarException < Exception
  end
  
  class Bar
  
    def error!
      raise BarException.new
    end
  
  end
end

class ErrorTest < Minitest::Test

  def test_exception
    assert_raises Foo::BarException do
      Foo::Bar.new.error!
    end
  end

end
