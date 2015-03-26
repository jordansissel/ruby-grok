$: << File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
require 'grok-pure'
require 'test/unit'

class GrokPatternCapturingTests < Test::Unit::TestCase
  def setup
    @grok = Grok.new
  end

  def test_capture_methods
    @grok.add_pattern("foo", ".*")
    @grok.compile("%{foo}")
    match = @grok.match("hello world")
    assert_respond_to(match, :captures)
    assert_respond_to(match, :subject)
    assert_respond_to(match, :each_capture)
  end

  def test_basic_capture
    @grok.add_pattern("foo", ".*")
    @grok.compile("%{foo}")
    input = "hello world"
    match = @grok.match(input)
    assert_equal("(?<foo>.*)", @grok.expanded_pattern)
    assert_kind_of(Grok::Match, match)
    assert_kind_of(Hash, match.captures)
    assert_equal(match.captures.length, 1)
    assert_kind_of(Array, match.captures["foo"])
    assert_equal(1, match.captures["foo"].length)
    assert_kind_of(String, match.captures["foo"][0])
    assert_equal(input, match.captures["foo"][0])

    match.each_capture do |key, val|
      assert(key.is_a?(String), "Grok::Match::each_capture should yield string,string, got #{key.class.name} as first argument.")
      assert(val.is_a?(String), "Grok::Match::each_capture should yield string,string, got #{key.class.name} as first argument.")
    end

    assert_kind_of(String, match.subject)
    assert_equal(input, match.subject)
  end

  def test_multiple_captures_with_same_name
    @grok.add_pattern("foo", "\\w+")
    @grok.compile("%{foo} %{foo}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(1, match.captures.length)
    assert_equal(2, match.captures["foo"].length)
    assert_equal("hello", match.captures["foo"][0])
    assert_equal("world", match.captures["foo"][1])
  end

  def test_multiple_captures
    @grok.add_pattern("foo", "\\w+")
    @grok.add_pattern("bar", "\\w+")
    @grok.compile("%{foo} %{bar}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["foo"].length)
    assert_equal(1, match.captures["bar"].length)
    assert_equal("hello", match.captures["foo"][0])
    assert_equal("world", match.captures["bar"][0])
  end

  def test_nested_captures
    @grok.add_pattern("foo", "\\w+ %{bar}")
    @grok.add_pattern("bar", "\\w+")
    @grok.compile("%{foo}")
    match = @grok.match("hello world")
    assert_not_equal(false, match)
    assert_equal(2, match.captures.length)
    assert_equal(1, match.captures["foo"].length)
    assert_equal(1, match.captures["bar"].length)
    assert_equal("hello world", match.captures["foo"][0])
    assert_equal("world", match.captures["bar"][0])
  end

  def test_nesting_recursion
    @grok.add_pattern("foo", "%{foo}")
    assert_raises(Grok::PatternError) do
      @grok.compile("%{foo}")
    end
  end

  def test_inline_define
    path = "#{File.dirname(__FILE__)}/../../../patterns/pure-ruby/base"
    @grok.add_patterns_from_file(path)
    @grok.compile("%{foo=%{IP} %{BASE10NUM:fizz}}")
    match = @grok.match("1.2.3.4 300.4425")
    assert_equal(3, match.captures.length)
    assert(match.captures.include?("foo"))
    assert(match.captures.include?("IP"))
    assert(match.captures.include?("fizz"))
  end
                

  def test_valid_capture_subnames
    name = "foo"
    @grok.add_pattern(name, "\\w+")
    subname = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_abc:def"
    expected_name = subname.split(":")[0]
    @grok.compile("%{#{name}:#{subname}}")
    match = @grok.match("hello")
    assert_not_equal(false, match)
    assert_equal(1, match.captures.length)
    assert_equal(1, match.captures["#{expected_name}"].length)
    assert_equal("hello", match.captures["#{expected_name}"][0])
  end

  def test_match_and_captures
    @pattern_line = '%{COMBINEDAPACHELOG}'
    @log_line = '31.184.238.164 - - [24/Jul/2014:05:35:37 +0530] "GET /logs/access.log HTTP/1.0" 200 69849 "http://8rursodiol.enjin.com" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.12785 YaBrowser/13.12.1599.12785 Safari/537.36" "www.dlwindianrailways.com"'
    grok = Grok.new
    path = "#{File.dirname(__FILE__)}/../../../patterns/pure-ruby/base"
    grok.add_patterns_from_file(path)
    grok.compile(@pattern_line, true)
    expected_map = Hash({"clientip"=>["31.184.238.164"], "ident"=>["-"], "auth"=>["-"],
        "timestamp"=>["24/Jul/2014:05:35:37 +0530"], "ZONE"=>["+0530"], "verb"=>["GET"],
        "request"=>["/logs/access.log"], "httpversion"=>["1.0"], "response"=>["200"], "bytes"=>["69849"],
        "referrer"=>["http://8rursodiol.enjin.com"], "port"=>[nil],
        "agent"=>["\"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.12785 YaBrowser/13.12.1599.12785 Safari/537.36\""]})
    actual_map = Hash.new { |h,k| h[k] = [] }
    grok.match_and_capture(@log_line) { |k, v| actual_map[k] << v}
    assert_equal(expected_map, actual_map)

    grok.compile('%{INT:foo}|%{WORD:foo}', true)
    actual_map = Hash.new { |h,k| h[k] = [] }
    grok.match_and_capture("123 world") { |k, v| actual_map[k] << v}
    assert_equal(actual_map, Hash({"foo"=>["123", nil]}))

    actual_map = Hash.new { |h,k| h[k] = [] }
    grok.match_and_capture("hello world") { |k, v| actual_map[k] << v}
    assert_equal(actual_map, Hash({"foo"=>[nil, "hello"]}))

  end

  def test_match_and_captures_coerce
    @pattern_line = '%{NUMBER:bytes:int} %{NUMBER:status}'
    @log_line = '12009 200'
    grok = Grok.new
    path = "#{File.dirname(__FILE__)}/../../../patterns/pure-ruby/base"
    grok.add_patterns_from_file(path)
    grok.compile(@pattern_line, true)
    expected_map = Hash({"bytes"=>[12009], "status"=>["200"]})
    actual_map = Hash.new { |h,k| h[k] = [] }
    grok.match_and_capture(@log_line) { |k, v| actual_map[k] << v}
    assert_equal(expected_map, actual_map)

    @pattern_line = '%{NUMBER:bytes:float} %{NUMBER:status}'
    @log_line = '12009.34 200'
    grok.compile(@pattern_line, true)
    expected_map = Hash({"bytes"=>[12009.34], "status"=>["200"]})
    actual_map = Hash.new { |h,k| h[k] = [] }
    grok.match_and_capture(@log_line) { |k, v| actual_map[k] << v}
    assert_equal(expected_map, actual_map)
  end

  def test_match_no_capture
    grok = Grok.new
    grok.compile("^403$")
    has_captures = false
    matched = grok.match_and_capture("403") { |k, v| has_captures = true}
    assert(matched, "Expected to match ^403$")
    assert(!has_captures)

    matched = grok.match_and_capture("abc 403") { |k, v| has_captures = true}
    assert(!matched, "Not expected to match ^403$")
    assert(!has_captures)
  end

  def test_match_alternation
    grok = Grok.new
    path = "#{File.dirname(__FILE__)}/../../../patterns/pure-ruby/base"
    grok.add_patterns_from_file(path)
    # test for alternation and cerced capture
    grok.compile("test (N/A|%{BASE10NUM:duration:int}ms)")
    original_value, coerced_value = nil
    grok.match_and_capture("test N/A") do |k, v, orig_v|
        coerced_value = v
        original_value = orig_v
    end
    assert_equal(original_value, nil)
    assert_equal(coerced_value, 0)

    grok.match_and_capture("test 28ms") do |k, v, orig_v|
        coerced_value = v
        original_value = orig_v
    end

    assert_equal(original_value, "28")
    assert_equal(coerced_value, 28)
  end

end
