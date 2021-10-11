image_repo ?= albertdixon/helmfile-render
image_tag ?= latest
tmpdir_prefix = render

manifests:
	@docker pull $(image_repo):$(image_tag) 2>/dev/null || true
	@docker run --rm -t \
                --volume=$(PWD):/workspace \
                --volume=$${TMPDIR:-/tmp}:$${TMPDIR:-/tmp} \
                --env TMPDIR=$${TMPDIR:-/tmp} \
                $(image_repo):$(image_tag) \
                --project-dir /workspace \
                --app "$(app)" \
                $(shell [[ $(debug) -eq 1 ]] && echo "--debug") \
                $(shell [[ "$(sync_manifests)" == true ]] && echo "--sync")

validate: manifests
	@echo "--> Validating rendered templates for $(namespace)/$(app)"
	@kubeconform \
		-ignore-missing-schemas \
		-exit-on-error \
		-summary \
		-n 8 \
		$(TMPDIR)/$(shell ls -t "$(TMPDIR)" | grep "$(tmpdir_prefix)-$(app)-" | head -n1)
