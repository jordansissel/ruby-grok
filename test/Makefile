.PHONY: test
test: test-pure test-ffi

.PHONY: test-pure
test-pure:
	JRUBY_OPTS="--1.9 -J-Xmx1024m" RUBYLIB="$$PWD/../lib" ruby pure-ruby/alltests.rb

.PHONY: test-ffi
test-ffi:
	JRUBY_OPTS=--1.9 RUBYLIB="$$PWD/../lib" ruby ffi-ruby/alltests.rb
