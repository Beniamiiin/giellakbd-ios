//
//  GiellaKeyboard.swift
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 24/10/2014.
//  Copyright (c) 2014
//

import UIKit

class SuggestionOp: Operation {
    let word: String
    weak var kbd: GiellaKeyboard?

    init (kbd: GiellaKeyboard, word: String) {
        self.kbd = kbd
        self.word = word
    }

    override func main() {
        if (isCancelled) {
            return
        }

        /*
        let suggestions = self.kbd?.zhfst?.suggest(word).prefix(3).flatMap { (pair) in
            pair.first as String
        }

        DispatchQueue.main.async {
            if let suggestions = suggestions {
                if let banner = self.kbd?.bannerView as? GiellaBanner {
                    banner.mode = .suggestion
                    banner.updateList(suggestions);
                }
            }
        }
        */
    }
}

/*
extension UnsafeMutablePointer where Pointee == vec_str_t {
    func toSwift() -> [String] {
        defer {
            speller_vec_free(self)
        }

        let rawItems = Array(UnsafeBufferPointer(start: pointee.ptr, count: pointee.len))

        return rawItems.map({ String(cString: $0!) })
    }
}
*/

open class GiellaKeyboard: KeyboardViewController {
    //var keyNames: [String: String]

    //var zhfst: ZHFSTOSpeller?

    let opQueue = OperationQueue()

    func getCurrentWord() -> String {
        let documentProxy = self.textDocumentProxy as UITextDocumentProxy

        guard let beforeContext = documentProxy.documentContextBeforeInput else {
            return ""
        }

        guard let lastWord = beforeContext.components(separatedBy: " ").last else {
            return ""
        }

        return lastWord
    }

    func updateSuggestions() {
        guard let banner = self.bannerView as? GiellaBanner else {
            return
        }

        let lastWord = getCurrentWord()

        if lastWord == "" {// || zhfst == nil {
            banner.updateList([])
            return
        }

        opQueue.cancelAllOperations()
        opQueue.addOperation(SuggestionOp(kbd: self, word: lastWord))
    }

    /*
    class Speller {
        private let handle: UnsafeMutableRawPointer

        init() {
            handle = speller_new()
        }

        deinit {
            speller_free(handle)
        }

        func suggest(_ word: String) -> [String] {
            let cstr = UnsafePointer(word.cString(using: .utf8)!)
            return speller_suggest(handle, cstr).toSwift()
        }
    }
    */

    let selectedKeyboardIndex: Int = Bundle.main.infoDictionary!["DivvunKeyboardIndex"] as! Int
    
    override open func viewDidLoad() {
        self.configure(with: selectedKeyboard(index: selectedKeyboardIndex))

        super.viewDidLoad()
    }

    override func contextChanged() {
        super.contextChanged()

        updateSuggestions()
    }

    override func keyPressed(_ key: Key) {
        let textDocumentProxy = self.textDocumentProxy as UIKeyInput

        textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))

        updateSuggestions()
    }

    /*
    override func didReceiveMemoryWarning(notification: NSNotification) {
        opQueue.cancelAllOperations()
        opQueue.addOperationWithBlock() {
            self.zhfst?.clearSuggestionCache()
        }
    }
    */

    func getPrimaryLanguage() -> String? {
        if let ex = Bundle.main.infoDictionary!["NSExtension"] as? [String: AnyObject]{
            if let attrs = ex["NSExtensionAttributes"] as? [String: AnyObject] {
                if let lang = attrs["PrimaryLanguage"] as? String {
                    return lang
                }
            }
        }

        return nil
    }

    func loadZHFST() {
        NSLog("%@", "Loading speller…")

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
            NSLog("%@", "Dispatching request to load speller…")

            guard let bundle = Bundle.main.path(forResource: "dicts", ofType: "bundle") else {
                NSLog("No dict bundle found; ZHFST not loaded.")
                return
            }

            guard let lang = self.getPrimaryLanguage() else {
                NSLog("No primary language found for keyboard; ZHFST not loaded.")
                return
            }

            let path = "\(bundle)/\(lang).zhfst"

            if !FileManager.default.fileExists(atPath: path) {
                NSLog("No speller at: \(path)")
                NSLog("ZHFSTOSpeller **not** loaded.")
                return
            }

            /*
            let zhfst = ZHFSTOSpeller()

            do {
                try zhfst?.readZhfst(path, tempDir: NSTemporaryDirectory())
            } catch let err as NSError {
                NSLog("%@", err)
                NSLog("ZHFSTOSpeller **not** loaded.")
                return
            }

            zhfst?.setQueueLimit(3)
            zhfst?.setWeightLimit(50)

            self.zhfst = zhfst
            */

            NSLog("%@", "ZHFSTOSpeller loaded!")
        }
    }

    override func createBanner() -> ExtraView? {
        return GiellaBanner(keyboard: self)
    }

    override func backspaceDown(_ sender: KeyboardKey) {
        super.backspaceDown(sender)

        updateSuggestions()
    }
    
    override func localName() -> String? {
        return KeyboardDefinition.definitions[selectedKeyboardIndex].name
    }
    
    func disableInput() {
        self.forwardingView.isUserInteractionEnabled = false

        // Workaround to kill current touches
        self.forwardingView.removeFromSuperview()
        self.view.addSubview(self.forwardingView)

        if self.lastKey != nil {
            super.hidePopup(self.lastKey!)
        }
    }

    func enableInput() {
        self.forwardingView.isUserInteractionEnabled = true
    }

    override func showLongPress() {
        super.showLongPress()

        if let keyView = self.lastKey {
            let key = self.layout!.keyForView(keyView)
            let longpresses = key!.longPressForCase(shiftState.uppercase())

            if longpresses.count > 0 {
                keyView.showLongpressPopup(keys: longpresses)
            }
        }
    }

    override func hideLongPress() {
        super.hideLongPress()

        if let banner = self.bannerView as? GiellaBanner {
            banner.updateList([])
        }
    }
}

enum BannerModes {
    case none, longPress, suggestion
}

class GiellaBanner: ExtraView {
    var keyboard: GiellaKeyboard
    var mode: BannerModes = .suggestion

    init(keyboard: GiellaKeyboard) {
        self.keyboard = keyboard
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMode(_ mode: BannerModes) {
        self.mode = mode;
    }

    @objc func handleBtnPress(_ sender: UIButton) {
        let kbd = self.keyboard
        let textDocumentProxy = kbd.textDocumentProxy as UITextDocumentProxy

        var text = sender.titleLabel?.text ?? ""

        if text == "" {
            return // Do nothing!
        }

        kbd.hideLongPress()

        if mode == .longPress {
            textDocumentProxy.insertText(text)
            mode = .suggestion

        } else if (mode == .suggestion) {
            kbd.hideLongPress()

            let lastWord = keyboard.getCurrentWord()

            for _ in 0..<(lastWord.count) {
                textDocumentProxy.deleteBackward()
            }

            if text.hasPrefix("\"") && text.hasSuffix("\"") {
                text = String(text[text.index(text.startIndex, offsetBy: 1)...text.index(text.endIndex, offsetBy: -2)])
            }

            textDocumentProxy.insertText(text)
            textDocumentProxy.insertText(" ")
        }

        kbd.contextChanged()

        if kbd.shiftState == ShiftState.enabled {
            kbd.shiftState = ShiftState.disabled
        }

        kbd.setCapsIfNeeded()
    }

    func applyConstraints(_ currentView: UIButton, prevView: UIView?, nextView: UIView?, firstView: UIView) {
        let parentView = self

        var leftConstraint: NSLayoutConstraint
        var rightConstraint: NSLayoutConstraint
        var topConstraint: NSLayoutConstraint
        var bottomConstraint: NSLayoutConstraint

        // Constrain to top of parent view
        topConstraint = NSLayoutConstraint(item: currentView, attribute: .top, relatedBy: .equal, toItem: parentView,
            attribute: .top, multiplier: 1.0, constant: 1)

        // Constraint to bottom of parent too
        bottomConstraint = NSLayoutConstraint(item: currentView, attribute: .bottom, relatedBy: .equal, toItem: parentView, attribute: .bottom, multiplier: 1.0, constant: -1)

        // If last, constrain to right
        if nextView == nil {
            rightConstraint = NSLayoutConstraint(item: currentView, attribute: .right, relatedBy: .equal, toItem: parentView, attribute: .right, multiplier: 1.0, constant: -1)
        } else {
            rightConstraint = NSLayoutConstraint(item: currentView, attribute: .right, relatedBy: .equal, toItem: nextView, attribute: .left, multiplier: 1.0, constant: -1)
        }

        // If first, constrain to left of parent
        if prevView == nil {
            leftConstraint = NSLayoutConstraint(item: currentView, attribute: .left, relatedBy: .equal, toItem: parentView, attribute: .left, multiplier: 1.0, constant: 1)
        } else {
            leftConstraint = NSLayoutConstraint(item: currentView, attribute: .left, relatedBy: .equal, toItem: prevView, attribute: .right, multiplier: 1.0, constant: 1)

            let widthConstraint = NSLayoutConstraint(item: firstView, attribute: .width, relatedBy: .equal, toItem: currentView, attribute: .width, multiplier: 1.0, constant: 0)

            widthConstraint.priority = UILayoutPriority(rawValue: 800)

            addConstraint(widthConstraint)
        }

        addConstraints([topConstraint, bottomConstraint, rightConstraint, leftConstraint])

    }

    @objc func buttonHighlight(_ sender: UIButton) {
        sender.backgroundColor = UIColor(red: 235.0/255.0, green: 237.0/255.0, blue: 239.0/255.0, alpha: 1.0)
    }

    @objc func buttonNormal(_ sender: UIButton) {
        sender.backgroundColor = UIColor(red: 187.0/255.0, green: 194.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    }

    func updateList(_ keys: [String]) {
        let sv = self.subviews

        for v in sv {
            v.removeFromSuperview()
        }

        var mutKeys = keys

        if mode == .suggestion {
            if mutKeys.count < 3 && keyboard.getCurrentWord() != "" {
                let k = "\"\(keyboard.getCurrentWord())\""
                if mutKeys.count == 0 {
                    mutKeys.append(k)
                } else {
                    mutKeys.insert(k, at: 0)
                }
            }
        }
        // If still less than 3!
        while mutKeys.count < 3 {
            mutKeys.append("")
        }

        for char in mutKeys {
            let btn = UIButton(type: .custom)

            btn.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            btn.setTitle(char, for: UIControlState())
            btn.sizeToFit()

            if let titleLabel = btn.titleLabel {
                titleLabel.font = UIFont.systemFont(ofSize: 18)
                titleLabel.numberOfLines = 1
                titleLabel.lineBreakMode = .byTruncatingHead
                titleLabel.baselineAdjustment = .alignCenters
            }

            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

            btn.translatesAutoresizingMaskIntoConstraints = false
            buttonNormal(btn)

            btn.setTitleColor(UIColor(white: 1.0, alpha: 1.0), for: UIControlState())
            btn.setTitleColor(UIColor.black, for: .highlighted)

            btn.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
            btn.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)

            for event in [UIControlEvents.touchDragOutside, .touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside] {
                btn.addTarget(self, action: #selector(GiellaBanner.buttonNormal(_:)), for: event)
            }

            for event in [UIControlEvents.touchDragInside, .touchDragEnter, .touchDown, .touchDragInside] {
                btn.addTarget(self, action: #selector(GiellaBanner.buttonHighlight(_:)), for: event)
            }

            btn.addTarget(self, action: #selector(GiellaBanner.handleBtnPress(_:)), for: .touchUpInside)

            self.addSubview(btn)
        }

        let firstBtn = self.subviews[0] as! UIButton
        let lastN = mutKeys.count-1
        var prevBtn: UIButton?
        var nextBtn: UIButton?

        for (n, view) in self.subviews.enumerated() {
            let btn = view as! UIButton

            if n == lastN {
                nextBtn = nil
            } else {
                nextBtn = self.subviews[n+1] as? UIButton
            }

            if n == 0 {
                prevBtn = nil
            } else {
                prevBtn = self.subviews[n-1] as? UIButton
            }

            applyConstraints(btn, prevView: prevBtn, nextView: nextBtn, firstView: firstBtn)
        }
    }
}

fileprivate func makeModeKey(to mode: Int, isMain: Bool = false) -> ModeChangeKey {
    let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    
    let cap: String
    
    switch mode {
    case 0:
        cap = "ABC"
    case 1:
        cap = "123"
    case 2:
        cap = "#+="
    default:
        cap = "???"
    }
    
    let keyModeChangeNumbers = ModeChangeKey()
    keyModeChangeNumbers.uppercaseKeyCap = mode == 1 && isPad && isMain ? ".?123" : cap
    keyModeChangeNumbers.toMode = mode
    
    return keyModeChangeNumbers
}

fileprivate func makeReturnKey(definition def: KeyboardDefinition) -> Key {
    let returnKey = Key(.return)
    returnKey.uppercaseKeyCap = def.enter
    returnKey.uppercaseOutput = "\n"
    returnKey.lowercaseOutput = "\n"
    return returnKey
}

fileprivate func addControls(_ defaultKeyboard: Keyboard, definition def: KeyboardDefinition, row: Int, page: Int, toMode mode: Int, isMain: Bool = false) {
    let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    
    defaultKeyboard.addKey(makeModeKey(to: mode, isMain: isMain), row: row, page: page)
    
    let keyboardChange = ChangeKey()
    // TODO: Hide globe key on iPhone X
//    if #available(iOSApplicationExtension 11.0, *) {
//        if UIInputViewController.init().needsInputModeSwitchKey {
//            defaultKeyboard.addKey(ChangeKey(), row: row, page: page)
//        }
//    } else {
//        defaultKeyboard.addKey(ChangeKey(), row: row, page: page)
//    }

    defaultKeyboard.addKey(keyboardChange, row: row, page: page)
    
    let settings = SettingsKey()
    defaultKeyboard.addKey(settings, row: row, page: page)
    
    let space = SpaceKey()
    space.uppercaseKeyCap = def.space
    space.uppercaseOutput = " "
    space.lowercaseOutput = " "
    defaultKeyboard.addKey(space, row: row, page: page)
    
    defaultKeyboard.addKey(isPad ? makeModeKey(to: mode, isMain: isMain) : makeReturnKey(definition: def), row: row, page: page)
    
    if isPad {
        let hideKey = HideKey()
        hideKey.uppercaseKeyCap = "⥥"
        defaultKeyboard.addKey(hideKey, row: row, page: page)
    }
}

func defaultControls(_ defaultKeyboard: Keyboard, definition def: KeyboardDefinition) -> Keyboard {
    let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    let lastRow = def.normal.count

    addControls(defaultKeyboard, definition: def, row: lastRow, page: 0, toMode: 1, isMain: true)

    for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 1)
    }

    var page1Row1Keys = ["-", "/", ":", ";", "(", ")", "$", "&", "@"]
    
    if !isPad {
        page1Row1Keys.append("\"")
    }
    
    for key in page1Row1Keys {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 1)
    }

    defaultKeyboard.addKey(makeModeKey(to: 2), row: 2, page: 1)
    
    var page1Row2Keys = [".", ",", "?", "!", "'"]
    
    if isPad {
        page1Row2Keys.append("\"")
    }
    
    for key in page1Row2Keys {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 1)
    }

    if isPad {
        addControls(defaultKeyboard, definition: def, row: 3, page: 1, toMode: 0)
        defaultKeyboard.addKey(BackspaceKey(), row: 0, page: 1)
        defaultKeyboard.addKey(makeReturnKey(definition: def), row: 1, page: 1)
        defaultKeyboard.addKey(makeModeKey(to: 2), row: 2, page: 1)
    } else {
        defaultKeyboard.addKey(BackspaceKey(), row: 2, page: 1)
        
        let keyModeChangeLetters = ModeChangeKey()
        defaultKeyboard.addKey(keyModeChangeLetters, row: 3, page: 1)
        defaultKeyboard.addKey(ChangeKey(), row: 3, page: 1)
        defaultKeyboard.addKey(SettingsKey(), row: 3, page: 1)
        defaultKeyboard.addKey(SpaceKey(hasName: false), row: 3, page: 1)
        defaultKeyboard.addKey(makeReturnKey(definition: def), row: 3, page: 1)
    }
    
    // Page 2
    
    for key in ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="] {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 0, page: 2)
    }

    var page2Row1Keys = ["_", "\\", "|", "~", "<", ">", "€", "£", "¥"]
    if !isPad {
        page2Row1Keys.append("•")
    }
    
    for key in page2Row1Keys {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 1, page: 2)
    }

    defaultKeyboard.addKey(makeModeKey(to: 1), row: 2, page: 2)
    
    for key in page1Row2Keys {
        let keyModel = Key(.specialCharacter)
        keyModel.setLetter(lower: key)
        defaultKeyboard.addKey(keyModel, row: 2, page: 2)
    }
    
    if isPad {
        defaultKeyboard.addKey(BackspaceKey(), row: 0, page: 2)
        defaultKeyboard.addKey(makeReturnKey(definition: def), row: 1, page: 2)
        defaultKeyboard.addKey(makeModeKey(to: 1), row: 2, page: 2)
        
        addControls(defaultKeyboard, definition: def, row: 3, page: 2, toMode: 0)
    } else {
        defaultKeyboard.addKey(BackspaceKey(), row: 2, page: 2)
        defaultKeyboard.addKey(ModeChangeKey(), row: 3, page: 2)
        defaultKeyboard.addKey(ChangeKey(), row: 3, page: 2)
        defaultKeyboard.addKey(SettingsKey(), row: 3, page: 2)
        defaultKeyboard.addKey(SpaceKey(hasName: false), row: 3, page: 2)
        defaultKeyboard.addKey(makeReturnKey(definition: def), row: 3, page: 2)
    }
    return defaultKeyboard
}

