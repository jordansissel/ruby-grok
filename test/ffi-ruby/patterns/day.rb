$: << File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
require 'grok'
require 'test/unit'

class DayPatternsTest < Test::Unit::TestCase
  def setup
    @grok = Grok.new
    path = "#{File.dirname(__FILE__)}/../../../../patterns/base"
    @grok.add_patterns_from_file(path)
    @grok.compile("%{DAY}")
  end

  def test_days
    days = %w{Mon Monday Tue Tuesday Wed Wednesday Thu Thursday Fri Friday
                Sat Saturday Sun Sunday}
    days.each do |day|
      match = @grok.match(day)
      assert_not_equal(false, day, "Expected #{day} to match.")
      assert_equal(day, match.captures["DAY"][0])
    end
  end

end
