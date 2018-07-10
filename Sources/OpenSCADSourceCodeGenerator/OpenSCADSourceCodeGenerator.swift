//
//  OpenSCADSourceCodeGenerator.swift
//  OpenSCADSourceCodeGenerator
//
//  Created by Jeremy Bannister on 7/3/18.
//

@_exported import Object3D

public struct OpenSCADSourceCodeGenerator {
  public static var resolutionMode: ResolutionMode = .production
  
  public static func sourceCode (for object: RawObject3D) -> String {
    return OpenSCADSourceCodeGenerator.sourceCode(for: object, shouldAddVariables: true)
  }
  
  internal static func sourceCode (for object: RawObject3D, shouldAddVariables: Bool) -> String {
    var generatedSourceCode = ""
    
    switch object {
    case .cube(position: let position, size: let size):
      let translation = OpenSCADSourceCodeGenerator.translationString(for: position)
      generatedSourceCode = "\(translation)cube(\(size.formattedForOpenSCAD));"
    case .cylinder(position: let position, lowerRadius: let lowerRadius, upperRadius: let upperRadius, depth: let depth):
      let translation = OpenSCADSourceCodeGenerator.translationString(for: position)
      generatedSourceCode = "\(translation)cylinder(r1 = \(lowerRadius.asOpenSCADVariable), r2 = \(upperRadius.asOpenSCADVariable), h = \(depth.asOpenSCADVariable)\(resolutionMode.resolutionModificationString));"
    case .polyhedron(position: let position, vertices: let vertices, faces: let faces):
      let translation = OpenSCADSourceCodeGenerator.translationString(for: position)
      let verticesDescription = vertices.map({ [$0.x, $0.y, $0.z].map({ $0.asOpenSCADVariable }) }).description.filter({ $0 != "\"" })
      generatedSourceCode = "\(translation)polyhedron(points = \(verticesDescription), faces = \(faces));"
      
    case .union(position: let position, rawObjects: let rawObjects):
      let translation = OpenSCADSourceCodeGenerator.translationString(for: position)
      let interiorSourceCode = rawObjects.map({ OpenSCADSourceCodeGenerator.sourceCode(for: $0, shouldAddVariables: false) }).joined(separator: "\n")
      generatedSourceCode = "\(translation)union () {\n\(interiorSourceCode)\n}"
      
    case .difference(position: let position, original: let original, subtractions: let subtractions):
      let translation = OpenSCADSourceCodeGenerator.translationString(for: position)
      let interiorSourceCode = ([original] + subtractions).map({ OpenSCADSourceCodeGenerator.sourceCode(for: $0, shouldAddVariables: false) }).joined(separator: "\n")
      generatedSourceCode = "\(translation)difference () {\n\(interiorSourceCode)\n}"
    }
    
    var variablesAtTopOfFile = ""
    if shouldAddVariables {
      for numberAndVariableName in openSCADVariables.sorted(by: { $0.1 < $1.1 }) {
        variablesAtTopOfFile += "\(numberAndVariableName.value) = \(numberAndVariableName.key);\n"
      }
      variablesAtTopOfFile += "\n"
    }
    return variablesAtTopOfFile + generatedSourceCode
  }
  
  internal static func translationString (for position: Position3D) -> String {
    return position == .zero ? "" : "translate(\(position.formattedForOpenSCAD)) "
  }
}


private var resolutionMode: OpenSCADSourceCodeGenerator.ResolutionMode { return OpenSCADSourceCodeGenerator.resolutionMode }
extension OpenSCADSourceCodeGenerator {
  public enum ResolutionMode {
    case development, production
    internal var resolutionModificationString: String {
      switch self {
      case .development: return ""
      case .production: return ", $fn=\(100.0.asOpenSCADVariable)"
      }
    }
  }
}

// Formatting
extension Position3D {
  var formattedForOpenSCAD: String {
    return "[\(x.asOpenSCADVariable), \(y.asOpenSCADVariable), \(z.asOpenSCADVariable)]"
  }
}
extension Size3D {
  var formattedForOpenSCAD: String {
    return "[\(width.asOpenSCADVariable), \(height.asOpenSCADVariable), \(depth.asOpenSCADVariable)]"
  }
}


// Variable Management (variables are for performance optimization)
private var nextUniqueShortString: UniqueShortString = .first
private func getNextUniqueShortString () -> UniqueShortString {
  let next = nextUniqueShortString
  nextUniqueShortString = nextUniqueShortString.next
  return next
}
private var openSCADVariables: [Double: String] = [:]
private extension Double {
  var asOpenSCADVariable: String {
    let variableName = openSCADVariables[self] ?? getNextUniqueShortString().string
    openSCADVariables[self] = variableName
    return variableName
  }
}
