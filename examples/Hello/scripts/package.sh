#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftAWSLambdaRuntime open source project
##
## Copyright (c) 2020 Apple Inc. and the SwiftAWSLambdaRuntime project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftAWSLambdaRuntime project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -eu

executable=$1

target=.build/lambda/$executable
rm -rf "$target"
mkdir -p "$target"
cp ".build/release/$executable" "$target/"
cp -Pv \
  /usr/lib/swift/linux/libBlocksRuntime.so \
  /usr/lib/swift/linux/libFoundation.so \
  /usr/lib/swift/linux/libFoundationNetworking.so \
  /usr/lib/swift/linux/libFoundationXML.so \
  /usr/lib/swift/linux/libdispatch.so \
  /usr/lib/swift/linux/libicudataswift.so \
  /usr/lib/swift/linux/libicudataswift.so.65 \
  /usr/lib/swift/linux/libicudataswift.so.65.1 \
  /usr/lib/swift/linux/libicui18nswift.so \
  /usr/lib/swift/linux/libicui18nswift.so.65 \
  /usr/lib/swift/linux/libicui18nswift.so.65.1 \
  /usr/lib/swift/linux/libicuucswift.so \
  /usr/lib/swift/linux/libicuucswift.so.65 \
  /usr/lib/swift/linux/libicuucswift.so.65.1 \
  /usr/lib/swift/linux/libswiftCore.so \
  /usr/lib/swift/linux/libswiftDispatch.so \
  /usr/lib/swift/linux/libswiftGlibc.so \
  "$target"
cd "$target"
ln -s "$executable" "bootstrap"
zip --symlinks lambda.zip *
