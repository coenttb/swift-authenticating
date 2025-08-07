// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let authenticating: Self = "Authenticating"
    static let authenticatingURLRouting: Self = "AuthenticatingURLRouting"
    static let authenticatingEmailAddress: Self = "AuthenticatingEmailAddress"
}

extension Target.Dependency {
    static var authenticating: Self { .target(name: .authenticating) }
    static var authenticatingURLRouting: Self { .target(name: .authenticatingURLRouting) }
    static var authenticatingEmailAddress: Self { .target(name: .authenticatingEmailAddress) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var urlRouting: Self { .product(name: "URLRouting", package: "swift-url-routing") }
    static var emailaddress: Self { .product(name: "EmailAddress", package: "swift-emailaddress-type") }
    static var rfc6750: Self { .product(name: "RFC_6750", package: "swift-rfc-6750") }
    static var rfc7617: Self { .product(name: "RFC_7617", package: "swift-rfc-7617") }
}

let package = Package(
    name: "swift-authenticating",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: .authenticating,
            targets: [.authenticating ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.2"),
        .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
        .package(url: "https://github.com/coenttb/swift-emailaddress-type", from: "0.0.1"),
        .package(url: "https://github.com/swift-web-standards/swift-rfc-6750", from: "0.0.1"),
        .package(url: "https://github.com/swift-web-standards/swift-rfc-7617", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .authenticating,
            dependencies: [
                .authenticatingURLRouting,
                .authenticatingEmailAddress,
                .rfc6750,
                .rfc7617,
                .urlRouting,
                .emailaddress,
                .dependencies
            ]
        ),
        .target(
            name: .authenticatingURLRouting,
            dependencies: [
                .rfc6750,
                .rfc7617,
                .urlRouting
            ]
        ),
        .testTarget(
            name: .authenticatingURLRouting.tests,
            dependencies: [
                .authenticatingURLRouting
            ]
        ),
        .target(
            name: .authenticatingEmailAddress,
            dependencies: [
                .rfc6750,
                .rfc7617,
                .emailaddress
            ]
        ),
        .testTarget(
            name: .authenticatingEmailAddress.tests,
            dependencies: [
                .authenticatingEmailAddress
            ]
        ),
        .testTarget(
            name: .authenticating.tests,
            dependencies: [
                .authenticating,
                .dependencies,
                .product(name: "DependenciesMacros", package: "swift-dependencies")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }
