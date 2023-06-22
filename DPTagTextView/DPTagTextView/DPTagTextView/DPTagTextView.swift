//
//  DPTagTextView.swift
//  TagNameDetection
//
//  Created by datt on 29/05/18.
//  Copyright © 2018 Datt. All rights reserved.
//

import UIKit

// MARK: - DPTag
public struct DPTag {
    public var id : String = UUID().uuidString
    public var name : String
    public var range: NSRange
    public var data : [String:Any] = [:]
    public var isHashTag: Bool = false
    public var customTextAttributes: [NSAttributedString.Key: Any]? = nil
}

// MARK: - DPTagTextViewDelegate
public protocol DPTagTextViewDelegate {
    func dpTagTextView(_ textView: DPTagTextView, didChangedTagSearchString strSearch: String, isHashTag: Bool)
    func dpTagTextView(_ textView: DPTagTextView, didInsertTag tag: DPTag)
    func dpTagTextView(_ textView: DPTagTextView, didRemoveTag tag: DPTag)
    func dpTagTextView(_ textView: DPTagTextView, didSelectTag tag: DPTag)
    func dpTagTextView(_ textView: DPTagTextView, didChangedTags arrTags: [DPTag])

    func textViewShouldBeginEditing(_ textView: DPTagTextView) -> Bool
    func textViewShouldEndEditing(_ textView: DPTagTextView) -> Bool
    func textViewDidBeginEditing(_ textView: DPTagTextView)
    func textViewDidEndEditing(_ textView: DPTagTextView)
    func textView(_ textView: DPTagTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    func textViewDidChange(_ textView: DPTagTextView)
    func textViewDidChangeSelection(_ textView: DPTagTextView)
    func textView(_ textView: DPTagTextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    func textView(_ textView: DPTagTextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}

public extension DPTagTextViewDelegate {
    func dpTagTextView(_ textView: DPTagTextView, didChangedTagSearchString strSearch: String, isHashTag: Bool) {}
    func dpTagTextView(_ textView: DPTagTextView, didInsertTag tag: DPTag) {}
    func dpTagTextView(_ textView: DPTagTextView, didRemoveTag tag: DPTag) {}
    func dpTagTextView(_ textView: DPTagTextView, didSelectTag tag: DPTag) {}
    func dpTagTextView(_ textView: DPTagTextView, didChangedTags arrTags: [DPTag]) {}
    
    func textViewShouldBeginEditing(_ textView: DPTagTextView) -> Bool { true }
    func textViewShouldEndEditing(_ textView: DPTagTextView) -> Bool { true }
    func textViewDidBeginEditing(_ textView: DPTagTextView) {}
    func textViewDidEndEditing(_ textView: DPTagTextView) {}
    func textView(_ textView: DPTagTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { true }
    func textViewDidChange(_ textView: DPTagTextView) {}
    func textViewDidChangeSelection(_ textView: DPTagTextView) {}
    func textView(_ textView: DPTagTextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
    func textView(_ textView: DPTagTextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { true }
}


open class DPTagTextView: UITextView {
    
    // MARK: - Properties
    open var mentionSymbol: String = "@"
    open var hashTagSymbol: String = "#"
    open var textViewAttributes: [NSAttributedString.Key: Any] = {
        [NSAttributedString.Key.foregroundColor: UIColor.black,
         NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
    }()

    open var mentionTagTextAttributes: [NSAttributedString.Key: Any] = {
        [NSAttributedString.Key.foregroundColor: UIColor.purple,
         NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
    }()
    
    open var hashTagTextAttributes: [NSAttributedString.Key: Any] = {
        [NSAttributedString.Key.foregroundColor: UIColor.orange,
         NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
    }()
    
    public private(set) var arrTags : [DPTag] = []
    open var dpTagDelegate : DPTagTextViewDelegate?
    open var allowsHashTagUsingSpace : Bool = true
    
    private var currentTaggingRange: NSRange?
    private var currentTaggingText: String? {
        didSet {
            if let tag = currentTaggingText, tag != oldValue {
                dpTagDelegate?.dpTagTextView(self, didChangedTagSearchString:tag, isHashTag: isHashTag)
            }
        }
    }
    private var tagRegex: NSRegularExpression {
        try! NSRegularExpression(pattern: "(\(mentionSymbol)|\(hashTagSymbol))([^\\s\\K]+)")
    }
    private var isHashTag = false
    private var tapGesture = UITapGestureRecognizer()
    
    
    // MARK: - init
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

}

// MARK: - Public methods
public extension DPTagTextView {
    
    func addTag(allText: String? = nil, tagText: String, id: String = UUID().uuidString, data : [String:Any] = [:], customTextAttributes: [NSAttributedString.Key: Any]? = nil , isAppendSpace: Bool = true) {
        guard let range = currentTaggingRange else { return }
        guard let allText = (allText == nil ? text : allText) else { return }
        
        let origin = (allText as NSString).substring(with: range)
        let tag = isHashTag ? hashTagSymbol.appending(tagText) : mentionSymbol.appending(tagText)
        let replace = isAppendSpace ? tag.appending(" ") : tag
        let changed = (allText as NSString).replacingCharacters(in: range, with: replace)
        let tagRange = NSMakeRange(range.location, tag.utf16.count)
        
        let dpTag = DPTag(id: id, name: tagText, range: tagRange, data: data, isHashTag: isHashTag, customTextAttributes: customTextAttributes)
        arrTags.append(dpTag)
        for i in 0..<arrTags.count-1 {
            var location = arrTags[i].range.location
            let length = arrTags[i].range.length
            if location > tagRange.location {
                location += replace.count - origin.count
                arrTags[i].range = NSMakeRange(location, length)
            }
        }
        
        text = changed
        updateAttributeText(selectedLocation: range.location+replace.count)
        dpTagDelegate?.dpTagTextView(self, didInsertTag: dpTag)
        dpTagDelegate?.dpTagTextView(self, didChangedTags: arrTags)
        isHashTag = false
    }
    
    func setTagDetection(_ isTagDetection : Bool, isEditable : Bool = false, isSelectable : Bool = false) {
        self.removeGestureRecognizer(tapGesture)
        if isTagDetection {
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnTextView(_:)))
            tapGesture.delegate = self
            self.addGestureRecognizer(tapGesture)
            self.isEditable = isEditable
            self.isSelectable = isSelectable
        } else {
            self.isEditable = true
            self.isSelectable = true
        }
    }
    
    func setText(_ text: String?, arrTags: [DPTag]) {
        self.text = text
        self.arrTags = arrTags
        updateAttributeText(selectedLocation: -1)
    }
    /// This will remove all the previously cached tags. Always use this function to clear the textfields with actions
    func clearText() {
        self.text = ""
        self.arrTags.removeAll()
    }
}


// MARK: - Private methods
private extension DPTagTextView {
    
    func setup() {
        delegate = self
    }
    
    @objc final func tapOnTextView(_ recognizer: UITapGestureRecognizer) {
    
        guard let textView = recognizer.view as? UITextView else {
            return
        }
        
        var location: CGPoint = recognizer.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let charIndex = textView.layoutManager.characterIndex(for: location, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard charIndex < textView.textStorage.length - 1 else {
            return
        }
        
        for i in 0 ..< arrTags.count {
            if arrTags[i].range.location <= charIndex && arrTags[i].range.location+arrTags[i].range.length > charIndex {
                dpTagDelegate?.dpTagTextView(self, didSelectTag: arrTags[i])
            }
        }
    }
    
    func matchedData(taggingCharacters: [Character], selectedLocation: Int, taggingText: String) -> (NSRange?, String?) {
        var matchedRange: NSRange?
        var matchedString: String?
        let tag = String(taggingCharacters.reversed())
        let textRange = NSMakeRange(selectedLocation-tag.count, tag.count)
        
        guard tag == mentionSymbol || tag == hashTagSymbol  else {
            let matched = tagRegex.matches(in: taggingText, options: .reportCompletion, range: textRange)
            if matched.count > 0, let range = matched.last?.range {
                matchedRange = range
                matchedString = (taggingText as NSString).substring(with: range).replacingOccurrences(of: isHashTag ? hashTagSymbol : mentionSymbol, with: "")
            }
            return (matchedRange, matchedString)
        }
        
        matchedRange = nil//textRange
        matchedString = nil//isHashTag ? hashTag : symbol
        return (matchedRange, matchedString)
    }
    
    func tagging(textView: UITextView) {
        let selectedLocation = textView.selectedRange.location
        let taggingText = (textView.text as NSString).substring(with: NSMakeRange(0, selectedLocation))
        let space: Character = " "
        let lineBrak: Character = "\n"
        var tagable: Bool = false
        var characters: [Character] = []
        
        for char in Array(taggingText).reversed() {
            if char == mentionSymbol.first {
                characters.append(char)
                isHashTag = false
                tagable = true
                break
            } else if char == hashTagSymbol.first {
                characters.append(char)
                isHashTag = true
                tagable = true
                break
            }
            else if char == space || char == lineBrak {
                tagable = false
                break
            }
            characters.append(char)
        }
        
        guard tagable, !isHashTag else {
            currentTaggingRange = nil
            currentTaggingText = nil
            return
        }
        
        let data = matchedData(taggingCharacters: characters, selectedLocation: selectedLocation, taggingText: taggingText)
        currentTaggingRange = data.0
        currentTaggingText = data.1
    }
    
    func updateAttributeText(selectedLocation: Int) {
        guard let text = text else { return }
        if text.isEmpty { arrTags.removeAll() }
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes(textViewAttributes, range: NSMakeRange(0, text.utf16.count))
        arrTags.forEach { (dpTag) in
            guard let customTextAttributes = dpTag.customTextAttributes else {
            attributedString.addAttributes(dpTag.isHashTag ? hashTagTextAttributes : mentionTagTextAttributes, range: dpTag.range)
                return
            }
            attributedString.addAttributes(customTextAttributes, range: dpTag.range)
        }
        // find hashtags
        let hashtags = text.findHashtags()
        hashtags.forEach {
            if $0.0 != hashTagSymbol {
                attributedString.addAttributes(hashTagTextAttributes, range: $0.1)
            }
        }
        attributedText = attributedString
        selectedRange = NSMakeRange(selectedLocation, 0)
    }
    
    var marketText: String? {
        if let marketRange = self.markedTextRange {
            return self.text(in: marketRange)
        }
        return nil
    }
    
    func fixedWhenMarketTextUnmatch() {
        var matched: [DPTag] = []
        for i in 0 ..< arrTags.count {
            var tag = arrTags[i]
            if let last = matched.last(where: { t in
                return t.name == tag.name
            }) {
                let text = (self.text as NSString).substring(from: last.range.location + last.range.length)
                let tagName = tag.isHashTag ? hashTagSymbol.appending(tag.name) : mentionSymbol.appending(tag.name)
                let range = (text as NSString).range(of: tagName)
                if range.length > 0 {
                    tag.range = NSRange(location: range.location + last.range.location + last.range.length, length: range.length)
                } else {
                    tag.range = NSRange(location: 0, length: 0)
                }
                arrTags[i] = tag
                matched.append(tag)
            } else {
                let tagName = tag.isHashTag ? hashTagSymbol.appending(tag.name) : mentionSymbol.appending(tag.name)
                let range = (self.text as NSString).range(of: tagName)
                if range.length > 0 {
                    tag.range = range
                } else {
                    tag.range = NSRange(location: 0, length: 0)
                }
                arrTags[i] = tag
                matched.append(tag)
            }
            
        }
        if self.marketText != nil {
            updateTypingAttributes()
        }
    }
    
    func updateTypingAttributes() {
        var attri = textViewAttributes
        attri[.backgroundColor] = UIColor.black.withAlphaComponent(0.1)
        self.typingAttributes = attri
    }
    
    func updateArrTags(range: NSRange, textCount: Int) {
        let marketText = self.marketText ?? ""
       
        if marketText.isEmpty == false {
            updateTypingAttributes()
        } else {
            arrTags = arrTags.filter({ (dpTag) -> Bool in
                if dpTag.range.location < range.location && range.location < dpTag.range.location+dpTag.range.length {
                    dpTagDelegate?.dpTagTextView(self, didRemoveTag: dpTag)
                    return false
                }
                if range.length > 0 {
                    if range.location <= dpTag.range.location && dpTag.range.location < range.location+range.length {
                        dpTagDelegate?.dpTagTextView(self, didRemoveTag: dpTag)
                        return false
                    }
                }
                return true
            })
        }
        
        for i in 0 ..< arrTags.count {
            var location = arrTags[i].range.location
            let length = arrTags[i].range.length
            if location >= range.location {
                if range.length > 0 {
                    if textCount > 1 {
                        location += textCount - range.length
                    } else {
                        location -= range.length
                    }
                } else {
                    location += textCount
                }
                arrTags[i].range = NSMakeRange(location, length)
            }
        }
        
        currentTaggingText = nil
        dpTagDelegate?.dpTagTextView(self, didChangedTags: arrTags)
    }
    
    func addHashTagWithSpace(_ replacementText: String, _ range: NSRange) {
        if isHashTag && replacementText == " " && allowsHashTagUsingSpace {
            let selectedLocation = selectedRange.location
            let newText = (text as NSString).replacingCharacters(in: range, with: replacementText)
            let taggingText = (newText as NSString).substring(with: NSMakeRange(0, selectedLocation + 1))
            if let tag = taggingText.sliceMultipleTimes(from: "#", to: " ").last {
                addTag(allText: newText, tagText: tag, isAppendSpace: false)
            }
        }
    }
    
}

// MARK: - UITextViewDelegate
extension DPTagTextView: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        tagging(textView: textView)
        updateAttributeText(selectedLocation: textView.selectedRange.location)
        dpTagDelegate?.textViewDidChange(self)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        tagging(textView: textView)
        fixedWhenMarketTextUnmatch()
        dpTagDelegate?.textViewDidChangeSelection(self)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "" {
            // check tag in list. if in list, we will replace mention or hashtag and remove from list
            if let currentTag = arrTags.first(where: { $0.range.location <= range.location && $0.range.location + $0.range.length > range.location
               }) {
                let currentText = textView.text ?? ""
                arrTags.removeAll {
                    $0.range.location <= range.location && $0.range.location + $0.range.length > range.location
                }
                let result = (currentText as NSString).replacingCharacters(in: currentTag.range, with: " ")
                textView.text = result
                self.currentTaggingText = nil
                currentTaggingRange = nil
                selectedRange = NSRange(location: currentTag.range.location + 1, length: 0)
                updateArrTags(range: currentTag.range, textCount: text.utf16.count)
                return true
            }
        }
        // when add character to current tag, remove current tag
        if text != "" {
            // check tag in list. if in list, we will replace mention or hashtag and remove from list
            if arrTags.first(where: { $0.range.location < range.location && $0.range.location + $0.range.length > range.location
            }) != nil {
                arrTags.removeAll {
                    $0.range.location < range.location && $0.range.location + $0.range.length > range.location
                }
                self.currentTaggingText = nil
                currentTaggingRange = nil
                updateArrTags(range: range, textCount: text.utf16.count)
                return true
            }
        }
//        addHashTagWithSpace(text, range)
        updateArrTags(range: range, textCount: text.utf16.count)
        return dpTagDelegate?.textView(self, shouldChangeTextIn: range, replacementText: text) ?? true
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        dpTagDelegate?.textViewShouldBeginEditing(self) ?? true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        dpTagDelegate?.textViewShouldEndEditing(self) ?? true
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        dpTagDelegate?.textViewDidBeginEditing(self)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        dpTagDelegate?.textViewDidEndEditing(self)
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        dpTagDelegate?.textView(self, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        dpTagDelegate?.textView(self, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension DPTagTextView : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - String extension
internal extension String {
    func sliceMultipleTimes(from: String, to: String) -> [String] {
        components(separatedBy: from).dropFirst().compactMap { sub in
            (sub.range(of: to)?.lowerBound).flatMap { endRange in
                String(sub[sub.startIndex ..< endRange])
            }
        }
    }
    
    func findHashtags() -> [(String, NSRange)] {
        var hashtags:[(String, NSRange)] = []
        let regex = try? NSRegularExpression(pattern: "(#[a-zA-Z0-9_\\p{Arabic}\\p{N}]*)", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                let range = NSRange(location:match.range.location, length: match.range.length)
                let tag = NSString(string: self).substring(with: range)
                hashtags.append((tag, range))
            }
        }
        return hashtags
    }
    
    func findMentions() -> [(String, NSRange)] {
        var hashtags:[(String, NSRange)] = []
        let regex = try? NSRegularExpression(pattern: "(@[^\\s\\K]+)", options: [])
        if let matches = regex?.matches(in: self, options:[], range:NSMakeRange(0, self.count)) {
            for match in matches {
                let range = NSRange(location:match.range.location, length: match.range.length)
                let tag = NSString(string: self).substring(with: range)
                hashtags.append((tag, range))
            }
        }
        return hashtags
    }
}

