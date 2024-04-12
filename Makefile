docs:
	./scripts/build-docs.sh

clean:
	rm -rf dist/

tf-apply-dev:
	cd tf/environments/dev/ && terraform apply

tf-apply-prod:
	cd tf/environments/prod/ && terraform apply

tf-apply-all: tf-apply-dev tf-apply-prod

.PHONY: docs clean tf-apply-all tf-apply-dev tf-apply-prod
