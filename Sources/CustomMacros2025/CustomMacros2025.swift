// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "CustomMacros2025Macros", type: "StringifyMacro")

@freestanding(expression)
public macro superStringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "CustomMacros2025Macros", type: "SuperStringifyMacro")

@attached(member, names: named(CodingKeys))
@attached(extension, conformances: Codable)
public macro AutoCodable() = #externalMacro(module: "CustomMacros2025Macros", type: "AutoCodableMacro")

@attached(member, names: named(ConsumableExperiment), named(getVariation(variationName:variables:)))
public macro ConsumableExperiment() = #externalMacro(module: "CustomMacros2025Macros", type: "ConsumableExperimentMacro")
