# Rebuild trigger: 1.15.4 release 2026-02-26
ARG GO_BUILDER=registry.access.redhat.com/ubi8/go-toolset:1.25.7-1772050971
ARG RUNTIME=registry.redhat.io/ubi8/ubi:latest@sha256:a2874895561a0f52e84c78c9c8b504922cd0dd03dc19d682a51c935d29330c55

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd-catalog/git-clone
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN cd image/git-init && go build -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -v -o /tmp/tektoncd-catalog-git-clone

FROM $RUNTIME
ARG VERSION=git-init-1.15.4

ENV BINARY=git-init \
    KO_APP=/ko-app \
    KO_DATA_PATH=/kodata

RUN dnf install -y openssh-clients git git-lfs shadow-utils

COPY --from=builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}
COPY head ${KO_DATA_PATH}/HEAD
RUN chgrp -R 0 ${KO_APP} && \
    chmod -R g+rwX ${KO_APP}

LABEL \
      com.redhat.component="openshift-pipelines-git-init-rhel8-container" \
      name="openshift-pipelines/pipelines-git-init-rhel8" \
      version=$VERSION \
      cpe="cpe:/a:redhat:openshift_pipelines:1.15::el8" \
      summary="Red Hat OpenShift Pipelines Git-init" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Git-init" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Git-init" \
      io.k8s.description="git-init is a binary that makes it easy to clone a repository from a Tekton Task. It is usually used via the git-clone Tasks." \
      io.openshift.tags="pipelines,tekton,openshift"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
# trigger rebuild 2026-02-14
