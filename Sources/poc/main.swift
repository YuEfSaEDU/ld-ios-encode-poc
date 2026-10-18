// main.swift - LaunchDarkly iOS SDK context-encoding PoC.
//
// How to run:
//   1. Open this folder (the one containing Package.swift).
//   2. Run: swift run poc
//   3. Read the three scenarios; scenarios 1 and 2 show "[LEAK]".
//
// It builds launchdarkly/ios-client-sdk at the pinned released version
// (11.7.0), encodes three local test contexts, and prints the encoded JSON
// plus explicit checks. No LaunchDarkly account is used and no network
// requests are made to LaunchDarkly.

import Foundation
import Darwin
import LaunchDarkly

func encodeContext(_ context: LDContext) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]
    let data = try encoder.encode(context)
    return String(decoding: data, as: UTF8.self)
}

print("=== LaunchDarkly iOS SDK context encoding PoC ===")
print("SDK under test: launchdarkly/ios-client-sdk 11.7.0")
print("")

var leakObserved = false

// Scenario 0 (sanity): a private attribute is correctly redacted when there
// is no attribute-name collision.
do {
    var builder = LDContextBuilder(key: "poc-user-0")
    _ = builder.trySetValue("ssn", .string("SECRET_VALUE_B"))
    builder.addPrivateAttribute(Reference("ssn"))
    let context = try builder.build().get()

    let json = try encodeContext(context)
    print("--- Scenario 0 (sanity): {\"ssn\": \"SECRET_VALUE_B\"}, \"ssn\" marked private ---")
    print(json)
    let secretPresent = json.contains("SECRET_VALUE_B")
    print("check: private value \"SECRET_VALUE_B\" present in output - expected: false, actual: \(secretPresent)")
    print("")
} catch {
    print("Scenario 0 error: \(error)")
    exit(2)
}

// Scenario 1: an attribute named "/ssn" collides with a private sibling
// attribute named "ssn".
do {
    var builder = LDContextBuilder(key: "poc-user-1")
    _ = builder.trySetValue("/ssn", .string("PUBLIC_VALUE_A"))
    _ = builder.trySetValue("ssn", .string("SECRET_VALUE_B"))
    builder.addPrivateAttribute(Reference("ssn"))
    let context = try builder.build().get()

    let json = try encodeContext(context)
    print("--- Scenario 1: {\"/ssn\": \"PUBLIC_VALUE_A\", \"ssn\": \"SECRET_VALUE_B\"}, \"ssn\" marked private ---")
    print(json)
    let secretPresent = json.contains("SECRET_VALUE_B")
    let originalPresent = json.contains("PUBLIC_VALUE_A")
    print("check A: private \"ssn\" value \"SECRET_VALUE_B\" present in output - expected: false, actual: \(secretPresent)\(secretPresent ? "   [LEAK]" : "")")
    print("check B: \"/ssn\" value \"PUBLIC_VALUE_A\" present in output - expected: true, actual: \(originalPresent)\(originalPresent ? "" : "   [value dropped]")")
    print("")
    if secretPresent && !originalPresent {
        leakObserved = true
    }
} catch {
    print("Scenario 1 error: \(error)")
    exit(2)
}

// Scenario 2: an attribute named "/name" collides with the private built-in
// "name" attribute.
do {
    var builder = LDContextBuilder(key: "poc-user-2")
    _ = builder.trySetValue("/name", .string("PUBLIC_NAME"))
    builder.name("SECRET_NAME")
    builder.addPrivateAttribute(Reference("name"))
    let context = try builder.build().get()

    let json = try encodeContext(context)
    print("--- Scenario 2: {\"/name\": \"PUBLIC_NAME\"}, \"name\" = \"SECRET_NAME\", \"name\" marked private ---")
    print(json)
    let namePresent = json.contains("SECRET_NAME")
    let originalPresent = json.contains("PUBLIC_NAME")
    print("check A: private \"name\" value \"SECRET_NAME\" present in output - expected: false, actual: \(namePresent)\(namePresent ? "   [LEAK]" : "")")
    print("check B: \"/name\" value \"PUBLIC_NAME\" present in output - expected: true, actual: \(originalPresent)\(originalPresent ? "" : "   [value dropped]")")
    print("")
    if namePresent && !originalPresent {
        leakObserved = true
    }
} catch {
    print("Scenario 2 error: \(error)")
    exit(2)
}

print("RESULT: leak observed = \(leakObserved)")
exit(leakObserved ? 0 : 1)
