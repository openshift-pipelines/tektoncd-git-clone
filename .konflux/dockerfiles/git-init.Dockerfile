ARG GO_BUILDER=brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.23
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:383329bf9c4f968e87e85d30ba3a5cb988a3bbde28b8e4932dcd3a025fd9c98c

FROM $GO_BUILDER AS builder

COPY image/git-init .
ENV GODEBUG="http2server=0"
RUN go build -ldflags="-X 'knative.dev/pkg/changeset.rev=${CHANGESET_REV:0:7}'" -mod=vendor -v -o /tmp/tektoncd-catalog-git-clone
#
#FROM $RUNTIME
#
#ENV BINARY=git-init \
#    KO_APP=/ko-app \
#    KO_DATA_PATH=/kodata
#
#COPY --from=builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}
#
#RUN microdnf install -y openssh-clients git git-lfs shadow-utils && \
#    chgrp -R 0 ${KO_APP} && \
#    chmod -R g+rwX ${KO_APP}
#
#LABEL \
#    com.redhat.component="openshift-pipelines-git-init-rhel8-container" \
#    name="openshift-pipelines/pipelines-git-init-rhel8" \
#    summary="Red Hat OpenShift Pipelines Git-init" \
#    maintainer="pipelines-extcomm@redhat.com" \
#    description="Red Hat OpenShift Pipelines Git-init" \
#    io.k8s.display-name="Red Hat OpenShift Pipelines Git-init" \
#    io.k8s.description="git-init is a binary that makes it easy to clone a repository from a Tekton Task. It is usually used via the git-clone Tasks." \
#    io.openshift.tags="pipelines,tekton,openshift"
#
#WORKDIR /licenses
#
#COPY LICENSE .
## Not adding the user to make sure git+ssh uses HOME to read client configuration
#RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
#USER 65532
#
#ENTRYPOINT ["/ko-app/git-init"]