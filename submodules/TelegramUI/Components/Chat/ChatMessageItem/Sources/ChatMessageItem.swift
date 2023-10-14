import Foundation
import UIKit
import Postbox
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import AccountContext
import ChatHistoryEntry
import ChatControllerInteraction
import TelegramPresentationData

public enum ChatMessageItemContent: Sequence {
    case message(message: Message, read: Bool, selection: ChatHistoryMessageSelection, attributes: ChatMessageEntryAttributes, location: MessageHistoryEntryLocation?)
    case group(messages: [(Message, Bool, ChatHistoryMessageSelection, ChatMessageEntryAttributes, MessageHistoryEntryLocation?)])
    
    public func effectivelyIncoming(_ accountPeerId: PeerId, associatedData: ChatMessageItemAssociatedData? = nil) -> Bool {
        if let subject = associatedData?.subject, case let .messageOptions(_, _, info) = subject, case .forward = info {
            return false
        }
        switch self {
            case let .message(message, _, _, _, _):
                return message.effectivelyIncoming(accountPeerId)
            case let .group(messages):
                return messages[0].0.effectivelyIncoming(accountPeerId)
        }
    }
    
    public var index: MessageIndex {
        switch self {
            case let .message(message, _, _, _, _):
                return message.index
            case let .group(messages):
                return messages[0].0.index
        }
    }
    
    public var firstMessage: Message {
        switch self {
            case let .message(message, _, _, _, _):
                return message
            case let .group(messages):
                return messages[0].0
        }
    }
    
    public var firstMessageAttributes: ChatMessageEntryAttributes {
        switch self {
            case let .message(_, _, _, attributes, _):
                return attributes
            case let .group(messages):
                return messages[0].3
        }
    }
    
    public func makeIterator() -> AnyIterator<(Message, ChatMessageEntryAttributes)> {
        var index = 0
        return AnyIterator { () -> (Message, ChatMessageEntryAttributes)? in
            switch self {
                case let .message(message, _, _, attributes, _):
                    if index == 0 {
                        index += 1
                        return (message, attributes)
                    } else {
                        index += 1
                        return nil
                    }
                case let .group(messages):
                    if index < messages.count {
                        let currentIndex = index
                        index += 1
                        return (messages[currentIndex].0, messages[currentIndex].3)
                    } else {
                        return nil
                    }
            }
        }
    }
}

public enum ChatMessageItemAdditionalContent {
    case eventLogPreviousMessage(Message)
    case eventLogPreviousDescription(Message)
    case eventLogPreviousLink(Message)
}

public protocol ChatMessageItem: ListViewItem {
    var presentationData: ChatPresentationData { get }
    var context: AccountContext { get }
    var chatLocation: ChatLocation { get }
    var associatedData: ChatMessageItemAssociatedData { get }
    var controllerInteraction: ChatControllerInteraction { get }
    var content: ChatMessageItemContent { get }
    var disableDate: Bool { get }
    var effectiveAuthorId: PeerId? { get }
    var additionalContent: ChatMessageItemAdditionalContent? { get }

    var headers: [ListViewItemHeader] { get }
    
    var message: Message { get }
    var read: Bool { get }
    var unsent: Bool { get }
    var sending: Bool { get }
    var failed: Bool { get }
}
