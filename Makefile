docs:
	./scripts/build-docs.sh

clean:
	rm -rf dist/

.PHONY: docs clean