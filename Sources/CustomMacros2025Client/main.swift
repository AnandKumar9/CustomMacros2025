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

print("The designated variation of \(FTUXMusicBandGreeting.self) experiment corresponds to below enum case in your code -")

let variation = FeatureFlag().getVariation(expressedBasedOn: FTUXMusicBandGreeting.self) as? FTUXMusicBandGreeting.ConsumableExperiment
print(variation ?? "nil")

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

    static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol? {
        
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
        
        
        return ConsumableExperiment.variationA(headerMessage: variables["headerMessage"]!)
    }
}

extension SampleExperiment : ExperimentProtocol {}
