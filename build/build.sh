#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO_BUILD_CMD="go build"

if [ -n "$DEBUG" ]; then
	set -x
	GO_BUILD_CMD="go build -v"
fi

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  PKG
  ARCH
  COMMIT_SHA
  REPO_INFO
  TAG
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable $var must be set"
    exit 1
  fi
done

if [ "$missing" = true ]; then
  exit 1
fi

export CGO_ENABLED=1
export GOARCH=${ARCH}

export GO_LDFLAGS="-linkmode=external -buildid= \
    -X ${PKG}/version.RELEASE=${TAG} \
    -X ${PKG}/version.COMMIT=${COMMIT_SHA} \
    -X ${PKG}/version.REPO=${REPO_INFO}"

go-build-static.sh -trimpath -o "rootfs/bin/${ARCH}/nginx-ingress-controller" "${PKG}/cmd/nginx"
go-build-static.sh -trimpath -o "rootfs/bin/${ARCH}/dbg" "${PKG}/cmd/dbg"
go-build-static.sh -trimpath -o "rootfs/bin/${ARCH}/wait-shutdown" "${PKG}/cmd/waitshutdown"

go-assert-static.sh rootfs/bin/${ARCH}/*
if [[ ${ARCH} != "s390x" ]]; then
  go-assert-boring.sh rootfs/bin/${ARCH}/*
fi
strip rootfs/bin/${ARCH}/*
