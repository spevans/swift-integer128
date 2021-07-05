# Integer128

Implementation of Int128 and UInt128 for Swift.

[![macOS](https://github.com/spevans/swift-integer128/workflows/macOS/badge.svg)](https://github.com/spevans/swift-integer128/actions/workflows/macos.yml)
[![Linux](https://github.com/spevans/swift-integer128/workflows/Linux/badge.svg)](https://github.com/spevans/swift-integer128/actions/workflows/linux.yml)


Requires Swift 5.1, all platforms supported.

Current version 0.0.2


## Adding `Integer128` as a Dependency

To use the `Integer128` library in a SwiftPM project,
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/spevans/swift-integer128", .branch("main")),
```


Then include `"Integer128"` as a dependency for your executable target:

```swift
.product(name: "Integer128", package: "swift-integer128")
```

```swift
let package = Package(
    name: "int128test",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "Int128Lib", targets: ["Int128Lib"]),
        .executable(
            name: "int128test",
            targets: ["int128test"]),
    ],
    dependencies: [
        .package(url: "https://github.com/spevans/swift-integer128", .branch("main")),

    ],
    targets: [
        .target(
            name: "int128test",
            dependencies: [ "Int128Lib"]),
        .target(
            name: "Int128Lib",
            dependencies: [.product(name: "Integer128", package: "swift-integer128")]),
    ]
)
```

Copyright (c) 2019 - 2020 Simon Evans.
