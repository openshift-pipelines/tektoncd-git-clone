ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.24 
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:34880b64c07f28f64d95737f82f891516de9a3b43583f39970f7bf8e4cfa48b7

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd-catalog/git-clone
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
ENV GOEXPERIMENT=strictfipsruntime
RUN cd image/git-init && go build -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -tags strictfipsruntime -v -o /tmp/tektoncd-catalog-git-clone

FROM $RUNTIME
ARG VERSION=git-init-next

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
      summary="Red Hat OpenShift Pipelines Git-init" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Red Hat OpenShift Pipelines Git-init" \
      io.k8s.display-name="Red Hat OpenShift Pipelines Git-init" \
      io.k8s.description="Red Hat OpenShift Pipelines Git-init" \
      io.openshift.tags="pipelines,tekton,openshift"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
