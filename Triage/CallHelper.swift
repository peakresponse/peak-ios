//
//  CallHelper.swift
//  Triage
//
//  Created by Francis Li on 12/5/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import CallKit

class CallHelper: NSObject, CXProviderDelegate {
    static let provider = {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        let provider = CXProvider(configuration: configuration)
        return provider
    }()
    static let controller = CXCallController()
    static let shared = CallHelper()

    var onAnswer: (() -> Void)?
    var onDecline: (() -> Void)?

    override init() {
        super.init()
        CallHelper.provider.setDelegate(self, queue: nil)
    }

    func ring(id: UUID, from name: String, answer: @escaping () -> Void, decline: @escaping () -> Void, completion: @escaping ((any Error)?) -> Void) {
        onAnswer = answer
        onDecline = decline
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: name)
        update.hasVideo = true
        CallHelper.provider.reportNewIncomingCall(with: id, update: update, completion: completion)
    }

    func start(id: UUID, to name: String, completion: @escaping ((any Error)?) -> Void) {
        let action = CXStartCallAction(call: id, handle: CXHandle(type: .generic, value: name))
        action.isVideo = true
        let transaction = CXTransaction(action: action)
        CallHelper.controller.request(transaction, completion: completion)
        CallHelper.provider.reportOutgoingCall(with: id, startedConnectingAt: nil)
    }

    func connected(id: UUID) {
        CallHelper.provider.reportOutgoingCall(with: id, connectedAt: nil)
    }

    func end(id: UUID, completion: @escaping ((any Error)?) -> Void) {
        let action = CXEndCallAction(call: id)
        CallHelper.controller.request(CXTransaction(action: action), completion: completion)
    }

    func ended(id: UUID, reason: CXCallEndedReason) {
        CallHelper.provider.reportCall(with: id, endedAt: nil, reason: reason)
    }

    // MARK: - CXProviderDelegat4e

    func providerDidReset(_ provider: CXProvider) {

    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        onAnswer?()
        onAnswer = nil
        onDecline = nil
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        onDecline?()
        onAnswer = nil
        onDecline = nil
        action.fulfill()
    }
}
