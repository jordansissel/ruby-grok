VERSION=$(shell awk -F\" '/version = / { print $$2 }' grok.gemspec)
GEM=jls-grok-$(VERSION).gem

.PHONY: default
default: $(GEM)

$(GEM):
	gem build grok.gemspec

clean:
	-rm -f $(GEM)

install: test-package
	gem install $(GEM)

.PHONY: test-package
test-package: $(GEM)
	# Sometimes 'gem build' makes a faulty gem.
	gem unpack jls-grok-$(VERSION).gem
	rm -rf jls-grok-$(VERSION)/

.PHONY: publish
publish: 
publish: test-package
	gem push $(GEM)
