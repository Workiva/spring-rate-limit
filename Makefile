.DEFAULT_GOAL: help
SHELL=/bin/bash -o pipefail

PORT := "8080"

# Cite: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## Display this help page
	@grep -E '^[a-zA-Z0-9/_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: clean ## Run tests
	./mvnw test

.PHONY: clean
clean: ## Clean
	./mvnw clean

.PHONY: compile
compile: clean ## Compile
	./mvnw compile

.PHONY: check
check: ## Run checks (spotbugs, checkstyle)
	./mvnw verify -DskipTests

.PHONY: package
package: ## Package
	./mvnw -q --errors package -am

.PHONY: verify
verify: clean ## Verify
	./mvnw -q --errors verify

.PHONY: process-resources
process-resources: ## process-resources
	./mvnw process-resources -q

.PHONY: install
install: clean ## install
	./mvnw -T 2C --errors install -DskipITs -Dhttp.keepAlive=false

.PHONY: install-dependencies
install-dependencies: clean ## install-dependencies
	./mvnw -q --errors install -Dmaven.test.skip=true -DskipTests -Dspotbugs.skip=true -Dcheckstyle.skip=true

.PHONY: force-clean
force-clean: ## Force clean
	./mvnw --errors clean -U
