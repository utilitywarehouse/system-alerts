SHELL=/bin/bash

hooks-install:
	-rm .git/hooks/pre-commit
	(cd .git/hooks/ && ln -s ../../scripts/pre-commit pre-commit)

hooks-check-rules-run:
	@GIT_CMD="git diff --name-only --diff-filter=d origin/main" \
	./scripts/pre-commit
