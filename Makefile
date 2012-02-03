
.PHONY: default
default: package

.PHONY: package
package:
	gem build grok.gemspec

.PHONY: test-package
test-package: GEM=$(shell ls -t jls-grok*.gem | head -1)
test-package:
	gem unpack $(GEM)

.PHONY: publish
publish: GEM=$(shell ls -t jls-grok*.gem | head -1)
publish: test-package
	gem push $(GEM)
