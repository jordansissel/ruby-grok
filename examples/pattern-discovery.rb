#!/usr/bin/env ruby
#

require "rubygems"
require "grok-pure"
require "pp"

grok = Grok.new

# Load some default patterns that ship with grok.
# See also: 
#   http://code.google.com/p/semicomplete/source/browse/grok/patterns/base
grok.add_patterns_from_file("patterns/pure-ruby/base")

# Using the patterns we know, try to build a grok pattern that best matches 
# a string we give. Let's try Time.now.to_s, which has this format;
# => Fri Apr 16 19:15:27 -0700 2010
input = "http://www.google.com/ and 00:de:ad:be:ef:00 with 'Something Nice'"
pattern = grok.discover(input)

#g = Grok.new
#g.add_patterns_from_file("patterns/pure-ruby/base")
#g.compile("%{MAC}")
#p g.match("00:de:ad:be:ef:00").captures

puts "Input: #{input}"
puts "Pattern: #{pattern}"
exit
grok.compile(pattern)

# Sleep to change time.
puts "Sleeping so time changes and we can test against another input."
sleep(2)
match = grok.match("Time is #{Time.now.to_s}")
puts "Resulting capture:"
pp match.captures

# When run, the output should look something like this:
# % ruby pattern-discovery.rb
# Pattern: Time is Fri %{SYSLOGDATE} %{BASE10NUM} 2010
# {"BASE10NUM"=>["-0700"],
#  "SYSLOGDATE"=>["Apr 16 19:17:38"],
#  "TIME"=>["19:17:38"],
#  "MONTH"=>["Apr"],
#  "MONTHDAY"=>["16"]}
