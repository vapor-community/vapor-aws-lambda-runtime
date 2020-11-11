import AWSLambdaEvents
import Vapor
@testable import VaporAWSLambdaRuntime
import XCTest

final class APIGatewayTests: XCTestCase {
    func testCreateAPIGatewayResponse() {
        let body = #"{"hello": "world"}"#
        let vaporResponse = Vapor.Response(
            status: .ok,
            headers: HTTPHeaders([
                ("Content-Type", "application/json"),
            ]),
            body: .init(string: body)
        )

        let response = APIGateway.Response(response: vaporResponse)

        XCTAssertEqual(response.body, body)
        XCTAssertEqual(response.multiValueHeaders?.count, 2)
        XCTAssertEqual(response.multiValueHeaders?["Content-Type"]?.first, "application/json")
        XCTAssertEqual(response.multiValueHeaders?["content-length"]?.first, String(body.count))
    }
}
