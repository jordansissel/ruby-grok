$: << File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
require 'grok-pure'
require 'test/unit'

class GrokPatternCapturingTests < Test::Unit::TestCase
  def setup
    @grok = Grok.new
    path = "#{File.dirname(__FILE__)}/../../../patterns/pure-ruby/base"
    @grok.add_patterns_from_file(path)
  end

  def test_multiline
    @grok.compile("hello%{GREEDYDATA}")
    match = @grok.match("hello world \nthis is fun")
    assert_equal(" world \nthis is fun", match.captures["GREEDYDATA"][0])

    match = @grok.match("hello world this is fun")
    assert_equal(" world this is fun", match.captures["GREEDYDATA"][0])
  end

end