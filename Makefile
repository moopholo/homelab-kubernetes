render_manifests_image_repo = albertdixon/helmfile-render
render_manifests_image_tag = latest
tmpdir_prefix = render

manifests:
	@docker pull $${RENDER_MANIFESTS_IMAGE_REPO:-$(render_manifests_image_repo)}:$${RENDER_MANIFESTS_IMAGE_TAG:-$(render_manifests_image_tag)} || true
	@docker run --rm -t \
                --volume=$(PWD):/workspace \
                --volume=$${TMPDIR:-/tmp}:$${TMPDIR:-/tmp} \
                --env TMPDIR=$${TMPDIR:-/tmp} \
                $${RENDER_MANIFESTS_IMAGE_REPO:-$(render_manifests_image_repo)}:$${RENDER_MANIFESTS_IMAGE_TAG:-$(render_manifests_image_tag)} \
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
