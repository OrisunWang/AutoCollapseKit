#!/bin/bash
# Reproducible isolated matrix; SIMULATOR_ID must select a usable installed device.
set -euo pipefail
ACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACK_DEVICE="${SIMULATOR_ID:?Set SIMULATOR_ID to an installed iOS simulator UUID}"
# Modern Xcode drops old deployment targets; the override is for validation only.
ACK_BUILD_TARGET="${BUILD_DEPLOYMENT_TARGET:-15.0}"
ACK_RUN_ID="$(date +%Y%m%d-%H%M%S)"
python3 "$ACK_ROOT/scripts/generate-validation.py"
for ACK_COMBINATION in core snapkit masonry both; do
  for ACK_LINKAGE in library framework; do
    ACK_FIXTURE="$ACK_ROOT/.build/fixtures/$ACK_COMBINATION-$ACK_LINKAGE"
    (cd "$ACK_FIXTURE" && pod install)
    # Signing stays untouched in the projects; simulator builds disable it at invocation.
    xcodebuild -workspace "$ACK_FIXTURE/ACKValidation.xcworkspace" \
      -scheme ACKValidation -destination "platform=iOS Simulator,id=$ACK_DEVICE" \
      -derivedDataPath "$ACK_FIXTURE/DerivedData" \
      -resultBundlePath "$ACK_FIXTURE/TestResults-$ACK_RUN_ID.xcresult" \
      -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO \
      IPHONEOS_DEPLOYMENT_TARGET="$ACK_BUILD_TARGET" test
  done
done
