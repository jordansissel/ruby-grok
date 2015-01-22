$: << File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
require 'grok-pure'
require 'test/unit'

class GrokBasicTests < Test::Unit::TestCase
  def setup
    @grok = Grok.new
  end

  def test_grok_methods
    assert_respond_to(@grok, :compile)
    assert_respond_to(@grok, :match)
    assert_respond_to(@grok, :expanded_pattern)
    assert_respond_to(@grok, :pattern)
  end

  def test_grok_compile_fails_on_invalid_expressions
    bad_regexps = ["[", "[foo", "?", "(?-"]
    bad_regexps.each do |regexp|
      assert_raise(RegexpError, "Should fail: /#{regexp}/") do
        @grok.compile(regexp)
      end
    end
  end

  def test_grok_compile_succeeds_on_valid_expressions
    good_regexps = ["[hello]", "(test)", "(?:hello)", "(?=testing)"]
    good_regexps.each do |regexp|
      assert_nothing_raised do
        @grok.compile(regexp)
      end
    end
  end

  def test_grok_pattern_is_same_as_compile_pattern
    pattern = "Hello world"
    @grok.compile(pattern)
    assert_equal(pattern, @grok.pattern)
  end

  # TODO(sissel): Move this test to a separate test suite aimed
  # at testing grok internals
  def test_grok_expanded_pattern_works_correctly
    @grok.add_pattern("test", "hello world")
    @grok.compile("%{test}")
    assert_equal("(?<test>hello world)", @grok.expanded_pattern)
  end

  def test_grok_load_patterns_from_file
    require 'tempfile'
    fd = Tempfile.new("grok_test_patterns.XXXXX")
    fd.puts "TEST \\d+"
    fd.close
    @grok.add_patterns_from_file(fd.path)
    @grok.compile("%{TEST}")
    assert_equal("(?<TEST>\\d+)", @grok.expanded_pattern)
  end

  def test_grok_expanded_unknown_pattern
    assert_raise(Grok::PatternError, "unknown pattern %{foo}") do
      @grok.compile("%{foo}")
    end
  end

  def test_grok_expanded_unknown_pattern_embedded
    @grok.add_pattern("test", "hello world")
    assert_raise(Grok::PatternError, "unknown pattern %{foo}") do
      @grok.compile("%{test} bar %{foo} baz")
    end
  end

  def test_grok_trailing_whitespace_in_pattern
    assert_raise(Grok::PatternError, "Trailing whitespace found in pattern: \"blah \"") do
      @grok.add_pattern("test", "blah ")
    end
  end
end
