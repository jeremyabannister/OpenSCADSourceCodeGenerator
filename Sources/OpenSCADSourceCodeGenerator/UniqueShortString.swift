//
//  UniqueShortString.swift
//  OpenSCADSourceCodeGenerator
//
//  Created by Jeremy Bannister on 7/3/18.
//

struct UniqueShortString {
  private let characters: [Character]
  var string: String { return characters.map({ String($0) }).joined() }
  
  init? (string: String) {
    let characters = Array(string)
    guard characters.filter({ !UniqueShortString.characterSet.contains($0) }).count == 0 else { return nil }
    self.init(trustedCharacters: characters)
  }
  
  private init (trustedCharacters: [Character]) {
    self.characters = trustedCharacters
  }
  
  static var first: UniqueShortString {
    guard let firstCharacter = characterSet.first else { return .blank }
    return UniqueShortString(trustedCharacters: [firstCharacter])
  }
}

extension UniqueShortString {
  var next: UniqueShortString {
    var newCharacters = characters
    
    for i in (0 ..< newCharacters.count).reversed() {
      guard let incrementedCharacter = self.incrementedCharacter(from: newCharacters[i]) else { return self }
      newCharacters[i] = incrementedCharacter.character
      if !incrementedCharacter.didCycle { return UniqueShortString(trustedCharacters: newCharacters) }
    }
    
    guard let firstCharacter = characterSet.first else { return self }
    return UniqueShortString(trustedCharacters: [firstCharacter] + newCharacters)
  }
}

private extension UniqueShortString {
  static let characterSet: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m"]
  static let blank: UniqueShortString = UniqueShortString(trustedCharacters: [])
  var characterSet: [Character] { return UniqueShortString.characterSet }
  
  func incrementedCharacter (from character: Character) -> (character: Character, didCycle: Bool)? {
    guard let index = characterSet.index(of: character) else { return nil }
    let mustCycle = index + 1 >= characterSet.count
    let incrementedIndex = mustCycle ? 0 : index + 1
    return (character: characterSet[incrementedIndex], didCycle: mustCycle)
  }
}
