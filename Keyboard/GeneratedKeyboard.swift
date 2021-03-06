// GENERATION STUB.
import UIKit

func addKeyRow(_ keyboard: Keyboard, definition def: KeyboardDefinition, row: Int) {
    for (key, upperKey) in zip(def.normal[row], def.shifted[row]) {
        let keyModel = Key(.character)
        keyModel.setLetter(lower: key, upper: upperKey)
        
        if let lp = def.longPress[upperKey] {
            keyModel.setUppercaseLongPress(lp)
        }
        
        if let lp = def.longPress[key] {
            keyModel.setLowercaseLongPress(lp)
        }
        
        keyboard.addKey(keyModel, row: row, page: 0)
    }
}

func selectedKeyboard(index: Int) -> Keyboard {
    let defaultKeyboard = Keyboard()
    
    let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    
    let def = KeyboardDefinition.definitions[index]
    defaultKeyboard.addKey(ShiftKey(), row: def.normal.count - 1, page: 0)
    
    for i in 0..<def.normal.count {
        addKeyRow(defaultKeyboard, definition: def, row: i)
    }
    
    if isPad {
        defaultKeyboard.addKey(BackspaceKey(), row: 0, page: 0)
        let returnKey = Key(.return)
        returnKey.uppercaseKeyCap = def.enter
        returnKey.uppercaseOutput = "\n"
        returnKey.lowercaseOutput = "\n"
        defaultKeyboard.addKey(returnKey, row: 1, page: 0)
        
        let commaKey = Key(.specialCharacter)
        commaKey.uppercaseKeyCap = "!\n,"
        commaKey.uppercaseOutput = "!"
        commaKey.lowercaseOutput = ","
        defaultKeyboard.addKey(commaKey, row: 2, page: 0)
        
        let periodKey = Key(.specialCharacter)
        periodKey.uppercaseKeyCap = "?\n."
        periodKey.uppercaseOutput = "?"
        periodKey.lowercaseOutput = "."
        defaultKeyboard.addKey(periodKey, row: 2, page: 0)
        
        defaultKeyboard.addKey(ShiftKey(), row: 2, page: 0)
    } else {
        /*
        let commaKey = Key(.SpecialCharacter)
        commaKey.uppercaseKeyCap = "!\n,"
        commaKey.uppercaseOutput = "!"
        commaKey.lowercaseOutput = ","
        defaultKeyboard.addKey(commaKey, row: 2, page: 0)
        
        let periodKey = Key(.SpecialCharacter)
        periodKey.uppercaseKeyCap = "?\n."
        periodKey.uppercaseOutput = "?"
        periodKey.lowercaseOutput = "."
        defaultKeyboard.addKey(periodKey, row: 2, page: 0)
        */
        defaultKeyboard.addKey(BackspaceKey(), row: def.normal.count - 1, page: 0)
    }
    
    return defaultControls(defaultKeyboard, definition: def)

    //return defaultKeyboard
}
