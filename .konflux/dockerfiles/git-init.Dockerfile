ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.22
ARG RUNTIME=registry.redhat.io/ubi8/ubi:latest@sha256:96ede92bab65df0386c9dabe6ec946aaa13a8717d2d5ad52d5d9a1d2e1f90e0f

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd-catalog/git-clone
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
RUN cd image/git-init && go build -ldflags="-X 'knative.dev/pkg/changeset.rev=${CHANGESET_REV:0:7}'" -mod=vendor -v -o /tmp/tektoncd-catalog-git-clone

FROM $RUNTIME
ARG VERSION=git-init-1.14.6

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
      cpe="cpe:/a:redhat:openshift_pipelines:1.14::el8" \
      io.openshift.tags="pipelines,tekton,openshift"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
