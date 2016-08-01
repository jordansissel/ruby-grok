require 'benchmark'
require 'grok-pure'
require 'jruby/profiler'

@pattern_line = '%{COMBINEDAPACHELOG}'
@log_line = '31.184.238.164 - - [24/Jul/2014:05:35:37 +0530] "GET /logs/access.log HTTP/1.0" 200 69849 "http://8rursodiol.enjin.com" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.12785 YaBrowser/13.12.1599.12785 Safari/537.36" "www.dlwindianrailways.com"'

def init_grok(named_captures_only)
  grok = Grok.new
  path = "#{File.dirname(__FILE__)}/../../patterns/pure-ruby/base"
  grok.add_patterns_from_file(path)
  grok.compile(@pattern_line, named_captures_only)
  return grok
end

Benchmark.bmbm(10) do |bm|
  bm.report("10m Named Captures On") do
    grok = init_grok(true)
    (1..10_000_000).each do
      match = grok.match(@log_line)
      match.each_capture { |name, val| }
    end
  end
  bm.report("10m Named Captures Off") do
    grok = init_grok(false)
    (1..10_000_000).each do
      match = grok.match(@log_line)
      match.each_capture { |name, val| }
    end
  end
end
