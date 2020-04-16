EXECUTABLE=VaporTodoLambda
LAMBDA_ZIP=lambda.zip

SWIFT_DOCKER_IMAGE=swift-al2-builder

clean_lambda:
	rm bootstrap || true
	rm lambda.zip || true

build_lambda: clean_lambda
	docker run \
			--rm \
			--volume "$(shell pwd)/../..:/src" \
			--workdir "/src/examples/VaporTodoLambda/" \
			$(SWIFT_DOCKER_IMAGE) \
			swift build -c release

package_lambda: #build_lambda
	rm -rf .build/lambda || true
	mkdir .build/lambda
	cp .build/release/$(EXECUTABLE) .build/lambda/bootstrap
	docker run \
			--rm \
			--volume "$(shell pwd)/../..:/src" \
			--workdir "/src/examples/VaporTodoLambda/" \
			$(SWIFT_DOCKER_IMAGE) \
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
				.build/lambda

	zip -r -j -y $(LAMBDA_ZIP) .build/lambda/*

