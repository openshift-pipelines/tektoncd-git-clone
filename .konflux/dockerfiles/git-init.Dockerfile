# Rebuild trigger: 1.15.4 release 2026-02-26 
ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
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
ARG VERSION=1.15

ENV BINARY=git-init \
    KO_APP=/ko-app \
    KO_DATA_PATH=/kodata

RUN dnf install -y openssh-clients git git-lfs shadow-utils

COPY --from=builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}
COPY head ${KO_DATA_PATH}/HEAD
RUN chgrp -R 0 ${KO_APP} && \
    chmod -R g+rwX ${KO_APP}

LABEL \
    com.redhat.component="openshift-pipelines-git-init-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.15::el9" \
    description="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.k8s.description="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.k8s.display-name="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.openshift.tags="tekton,openshift,tektoncd-git-clone,git-init" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-git-init-rhel9" \
    summary="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    version="v1.15.5"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
# trigger rebuild 2026-02-14
