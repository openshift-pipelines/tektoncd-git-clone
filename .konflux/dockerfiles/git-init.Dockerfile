ARG GO_BUILDER=registry.redhat.io/ubi9/go-toolset:latest@sha256:51eef2836e5223c41577757c30544fbfb3f0710f3436b70b82d2195e35fcb743
ARG UBI_RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:08d4c70f1baf6537a0728656cf7942d561e74a35916509d205b6519861266352

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/tektoncd-catalog/git-clone
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
COPY head HEAD
ENV GODEBUG="http2server=0"
ENV GOEXPERIMENT=strictfipsruntime
RUN cd image/git-init && go build -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat HEAD)'" -mod=vendor -tags strictfipsruntime -v -o /tmp/tektoncd-catalog-git-clone

FROM $UBI_RUNTIME
ARG VERSION=1.23

ENV BINARY=git-init \
    KO_APP=/ko-app \
    KO_DATA_PATH=/kodata

RUN microdnf install -y openssh-clients git git-lfs shadow-utils

COPY --from=builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}
COPY head ${KO_DATA_PATH}/HEAD
RUN chgrp -R 0 ${KO_APP} && \
    chmod -R g+rwX ${KO_APP}

LABEL \
    com.redhat.component="openshift-pipelines-git-init-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.23::el9" \
    description="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.k8s.description="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.k8s.display-name="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    io.openshift.tags="tekton,openshift,tektoncd-git-clone,git-init" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-git-init-rhel9" \
    summary="Red Hat OpenShift Pipelines tektoncd-git-clone git-init" \
    version="v1.23.5"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
