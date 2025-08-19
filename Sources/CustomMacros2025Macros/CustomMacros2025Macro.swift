import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MacroLog: DiagnosticMessage {
    var diagnosticID: SwiftDiagnostics.MessageID
    
    let message: String
    let severity: DiagnosticSeverity
    let id = MessageID(domain: "AutoCodableMacros", id: "log")
}

extension MacroLog {
    static func note(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .note)
    }
    static func warning(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .warning)
    }
    static func error(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .error)
    }
}

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct SuperStringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        print("Hi there")
        context.diagnose(Diagnostic(node: node, message: MacroLog.note("Expanding it")))
        
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description.uppercased()))"
    }
}

public struct AutoCodableMacro: MemberMacro, ExtensionMacro {

  // Inject the CodingKeys enum as a member
  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf decl: some DeclGroupSyntax,
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    let storedNames: [String] = decl.memberBlock.members.compactMap { member in
        
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return nil }
        
      if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) == true {
        return nil
      }
        
      guard let binding = varDecl.bindings.first,
            binding.accessorBlock == nil,
            let ident = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else { return nil }
      
        return ident
    }

    let cases = storedNames.map { "case \($0)" }.joined(separator: "\n    ")
      
    let codingKeysEnum: DeclSyntax = """
    enum CodingKeys: String, CodingKey {
        \(raw: cases)
    }
    """
    return [codingKeysEnum]
  }

  // Provide the `: Codable` via an extension macro
  public static func expansion(of node: AttributeSyntax,
                               attachedTo declaration: some DeclGroupSyntax,
                               providingExtensionsOf type: some TypeSyntaxProtocol,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {

    // Empty extension that adds conformance
    let declSyntax: DeclSyntax = """
    extension \(type): Codable {}
    """
    guard let ext = declSyntax.as(ExtensionDeclSyntax.self) else { return [] }
    return [ext]
  }
}

public struct ConsumableExperimentMacro: MemberMacro {
    public static func expansion(of attribute: AttributeSyntax, providingMembersOf decl: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {

        // Support only enums
        guard let enumDecl = decl.as(EnumDeclSyntax.self) else { return [] }

        // MARK: STEP 1 - Iterate through all the existing cases in the enum
        // Collect the full expression for all the cases that need to be retained. Cases `.on` and `.off` will be filtered out.
        var retainedCaseLines: [String] = []

        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

            for element in caseDecl.elements {
                let caseName = element.name.text
                
                guard ((caseName.caseInsensitiveCompare("on") != .orderedSame) && (caseName.caseInsensitiveCompare("off") != .orderedSame)) else {
                    continue
                }

                let caseParameters = element.parameterClause?.description ?? ""
                
                retainedCaseLines.append("case \(caseName)\(caseParameters)")
            }
        }

        // MARK: STEP 2 - Build the nested enum conforming to `ConsumableExperimentProtocol` protocol
        // If there were no cases to retain, generate an empty enum still.
        let nestedEnumCasesSource = retainedCaseLines.joined(separator: "\n")

        let nestedEnumFullSource =
        """
        enum ConsumableExperiment: ConsumableExperimentProtocol {
            \(nestedEnumCasesSource)
        }
        """
        
        // MARK: STEP 3 - Build the getVariation() static function that returns a mapped instance of the nested enum
        // (NOTE/TODO - This part of the code can be optimized to reuse the parsing done already.)
        
        let allCasesNestedEnum: [(caseName: String, associatedVariables: [String])] = retainedCaseLines.compactMap { caseLine in
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
        
        var staticFuncDefinitionSource: String = ""
        for (index, caseDetails) in allCasesNestedEnum.enumerated() {
            let elsePrefixIfNeeded = (index > 0) ? "else ":""
            
            let associatedVariablesArray: [String] = caseDetails.associatedVariables.map { associatedVariable in
                let trimmedVariable = associatedVariable.trimmingCharacters(in: .whitespaces)
                return "\(trimmedVariable): (variables[\"\(trimmedVariable)\"] ?? \"\")"
            }
            let associatedVariablesString = associatedVariablesArray.joined(separator: ", ")
            let associatedVariablesFullSnippet = (!associatedVariablesString.isEmpty) ? "(\(associatedVariablesString))" : ""
            

            let caseToBeReturned = "ConsumableExperiment.\(caseDetails.caseName)" + associatedVariablesFullSnippet
            print(caseToBeReturned)
            
            staticFuncDefinitionSource.append("\(elsePrefixIfNeeded)if (variationName.caseInsensitiveCompare(\"\(caseDetails.caseName)\") == .orderedSame) { return \(caseToBeReturned) }\n")
        }
        staticFuncDefinitionSource.append((allCasesNestedEnum.count > 0) ? "else {return nil}" : "return nil")
        
        let staticFuncFullSource =
        """
        static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol? {
            // Use this comment for debugging - \(retainedCaseLines)
            \(staticFuncDefinitionSource)
        }
        """

        let nestedEnumDecl: DeclSyntax = DeclSyntax(stringLiteral: nestedEnumFullSource)
        let staticFuncDecl: DeclSyntax = DeclSyntax(stringLiteral: staticFuncFullSource)

        return [nestedEnumDecl, staticFuncDecl]
    }    
}

@main
struct CustomMacros2025Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        SuperStringifyMacro.self,
        AutoCodableMacro.self,
        ConsumableExperimentMacro.self
    ]
}
