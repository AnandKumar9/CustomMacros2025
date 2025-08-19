import CustomMacros2025
import Foundation

let a = 34
let b = 50

let (result1, code1) = #stringify(a + b)
let (result2, code2) : (Int, String) = #superStringify(a + b)

print("The value \(result2) was produced by the code \"\(code2)\"")

@AutoCodable
struct User {
    let id: Int
    var name: String
    var nickname: String?
    // computed property: won’t appear in CodingKeys
    var uppercasedName: String { name.uppercased() }
}

let userA = User(id: 1, name: "Mark", nickname: "Junior")
print(User.CodingKeys.id)

//let variation = FeatureFlag().getVariation(expressedBasedOn: FeatureXExperiment.self) as! FeatureXExperiment.ConsumableExperiment
let variation = FeatureFlag().getVariation(expressedBasedOn: MusicBand.self) as? MusicBand.ConsumableExperiment
print(variation ?? "nil")

//let c = SampleExperiment.getVariation(variationName: "variationB", variables: ["headerMessage":"Hi"])

/*
The attached macro should
 1. Create a nested enum skipping the cases `on` and `off`, but retaining every other case. Declare a conformance to ConsumableExperimentProtocol.
 2. Add the static function getVariation(), along with the implementation
 */

enum SampleExperiment {
    case on
    case off
    case variationA(headerMessage: String)
    case variationB(headerMessage: String)
    
    static var retainedCaseLines: [String] {
        ["case variationA(headerMessage: String)",
         "case variationB(headerMessage: String, arg2: String)",
         "case variationC"]
    }
    
    enum ConsumableExperiment: ConsumableExperimentProtocol {
        case variationA(headerMessage: String)
        case variationB(headerMessage: String)
    }
    
//    static var retainedCaseLines: [String] {
//        ["case variationA(headerMessage: String)",
//         "case variationB(headerMessage: String, arg2: String)",
//         "case variationC"]
//    }
    
    static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol? {
        print("Inside")
        
//        let allCaseNames: [String] = SampleExperiment.retainedCaseLines.compactMap { caseLine in
//            let caseLineWithoutCaseKeyword = caseLine.replacingOccurrences(of: "case ", with: "")
//            let caseName = caseLineWithoutCaseKeyword.split(separator: "(").first?.trimmingCharacters(in: .whitespaces)
//            
//            return caseName
//        }
//        print(allCaseNames)
        
        let allCases: [(caseName: String, associatedVariables: [String])] = SampleExperiment.retainedCaseLines.compactMap { caseLine in
            let caseLineWithoutCaseKeyword = caseLine.replacingOccurrences(of: "case ", with: "")
            let caseName = caseLineWithoutCaseKeyword.split(separator: "(").first?.trimmingCharacters(in: .whitespaces)
            
            guard let caseName else { return nil }
            
            var argumentsBlob: String? = nil
            
            if let start = caseLine.firstIndex(of: "("),
               let end = caseLine.firstIndex(of: ")") {
                argumentsBlob = String(caseLine[caseLine.index(after: start)..<end])
            }
            
            guard let argumentsBlob else { return (caseName: caseName, associatedVariables: []) }
            
            let arguments: [String] = argumentsBlob.split(separator: ",").compactMap { ($0.split(separator: ":").first) }.map { String($0) }
            
            return (caseName: caseName, associatedVariables: arguments)
        }
        
        var longCodeSnippet: String = ""
        for (index, caseDetails) in allCases.enumerated() {
            let elsePrefixIfNeeded = (index > 0) ? "else ":""
            
            let associatedVariablesArray: [String] = caseDetails.associatedVariables.map { associatedVariable in
                let trimmedVariable = associatedVariable.trimmingCharacters(in: .whitespaces)
                return "\(trimmedVariable): (variables[\"\(trimmedVariable)\"] ?? \"\")"
            }
            let associatedVariablesString = associatedVariablesArray.joined(separator: ", ")
            let associatedVariablesFullSnippet = (!associatedVariablesString.isEmpty) ? "(\(associatedVariablesString))" : ""
            

            let caseToBeReturned = "ConsumableExperiment.\(caseDetails.caseName)" + associatedVariablesFullSnippet
            print(caseToBeReturned)
            
            longCodeSnippet.append("\(elsePrefixIfNeeded)if variationName == \"\(caseDetails.caseName)\" { return \(caseToBeReturned) }\n")
        }
        longCodeSnippet.append((allCases.count > 0) ? "else {return nil}" : "return nil")
        print(longCodeSnippet)
        
        
//        return ConsumableExperiment.TheRollingStones(preferredMember: (variables["preferredMember"] ?? ""), song: (variables["song"] ?? ""))
        
        
//        let matchingCaseLine: String = SampleExperiment.retainedCaseLines.first(where: { $0.hasPrefix("case \(variationName)")})!
//        print(matchingCaseLine)
//        
//        var argumentsBlob: String? = nil
//        
//        if let start = matchingCaseLine.firstIndex(of: "("),
//           let end = matchingCaseLine.firstIndex(of: ")") {
//            argumentsBlob = String(matchingCaseLine[matchingCaseLine.index(after: start)..<end])
//        }
//        
//        print("argumentsBlob - \(argumentsBlob!)")
//        let arguments = argumentsBlob!.split(separator: ",").flatMap { $0.split(separator: ":").first }
//        print(arguments)
//        let associatedDataChunks: [String] = arguments.compactMap { argument in
//            guard let value = variables[String(argument)] else { return nil }
//            return argument + ": \"" +  value + "\""
//        }
//        let associatedDataSnippet = associatedDataChunks.joined(separator: ", ")
//        print("associatedDataSnippet - \(associatedDataSnippet)")
//        
//        let token = variationName + "(" + associatedDataSnippet + ")" // "\(variationName)\(\(associatedDataSnippet)\)"
//        print(token)
        
        
        return ConsumableExperiment.variationA(headerMessage: variables["headerMessage"]!)
    }
}

extension SampleExperiment : ExperimentProtocol {}

@ConsumableExperiment
enum MusicBand: ExperimentProtocol {
    case on
    case off
    case TheRollingStones(preferredMember: String, song: String)
    case LedZeppelin(preferredMember: String, song: String)
    
//    static func test_getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol? {
//        if variationName == "TheRollingStones" {
//            return ConsumableExperiment.TheRollingStones(preferredMember: (variables["preferredMember"] ?? ""), song: (variables["song"] ?? ""))
//        } else if variationName == "LedZeppelin" {
//            return nil
//        }
//        return nil
//    }
}

let n = MusicBand.TheRollingStones(preferredMember: "m", song: "n",)
