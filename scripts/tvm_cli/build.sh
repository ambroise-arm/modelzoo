#! /usr/bin/env bash
# Copyright 2020-2021 Autoware Foundation. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

IMAGE_NAME="autoware/model-zoo-tvm-cli"
TAG_NAME="local"
FROM_ARG="ubuntu:18.04"
TARGET_PLATFORM=""

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "    -c,--cuda              Build TVM cli with cuda enabled."
    echo "    -h,--help              Display the usage and exit."
    echo "    -i,--image-name <name> Set docker images name."
    echo "                           Default: $IMAGE_NAME"
    echo "    -t,--tag <tag>         Tag use for the docker images."
    echo "                           Default: $TAG_NAME"
    echo "    --platform <platform>  Use buildx and set target platform."
    echo "                           Possible values: amd64, arm64"
    echo ""
}

OPTS=$(getopt --options chi:t: \
         --long cuda,help,image-name:,tag:,platform: \
         --name "$0" -- "$@")
eval set -- "$OPTS"

while true; do
  case $1 in
    -c|--cuda)
      FROM_ARG="nvidia/cuda-arm64:11.1-devel-ubuntu18.04"
      if [[ $(uname -a) == *"x86_64"* ]]; then
        FROM_ARG="nvidia/cuda:10.1-devel-ubuntu18.04"
      fi
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -i|--image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -t|--tag)
      TAG_NAME="$2"
      shift 2
      ;;
    --platform)
      TARGET_PLATFORM="$2"
      shift 2
      ;;
    --)
      if [ -n "$2" ];
      then
        echo "Invalid parameter: $2"
        exit 1
      fi
      break
      ;;
    *)
      echo "Invalid option"
      exit 1
      ;;
  esac
done

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

DOCKER_FILE="Dockerfile.dependencies.${TARGET_PLATFORM}"
BUILD_CONTEXT_DIR=${SCRIPT_PATH}
export DOCKER_CLI_EXPERIMENTAL=enabled

# Build base image with all dependencies
docker buildx build -f "${SCRIPT_PATH}"/"${DOCKER_FILE}" \
             --build-arg FROM_ARG="${FROM_ARG}" \
             -t "${IMAGE_NAME}":"${TAG_NAME}" \
             --platform ${TARGET_PLATFORM} \
             --progress plain \
             --load \
                "${BUILD_CONTEXT_DIR}"
