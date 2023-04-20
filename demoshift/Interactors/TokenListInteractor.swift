//
//  TokenListInteractor.swift
//  demoshift
//
//  Created by Vova Badyaev on 24.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine


class TokenListInteractor {
    private let pcscWrapper: PcscWrapper
    private var state: TokenListState

    private var cancellable = Set<AnyCancellable>()
    private let semaphore = DispatchSemaphore.init(value: 0)

    init(state: TokenListState, _ pcscWrapper: PcscWrapper) {
        self.state = state
        self.pcscWrapper = pcscWrapper

        self.pcscWrapper.readers
            .receive(on: DispatchQueue.main)
            .assign(to: \.readers, on: state)
            .store(in: &cancellable)

        TokenManager.shared.tokens
            .receive(on: DispatchQueue.main)
            .sink { tokens in
                state.tokens = tokens.sorted(by: { a, b in
                    return !a.supportedInterfaces.contains(.BT) && b.supportedInterfaces.contains(.BT)
                })
            }
            .store(in: &cancellable)
    }

    func dismissSheet() {
        state.sheetType = nil
        state.taskStatus.errorMessage = ""
    }

    func didSelectToken(_ serial: String = "", type: TokenInterface) {
        state.selectedTokenType = type
        state.sheetType = .pinInput
        state.selectedTokenSerial = serial
    }

    func readCerts(withPin pin: String) {
        do {
            let isNFC = state.selectedTokenType == .NFC

            defer {
                if isNFC {
                    try? stopNfc(withMessage: "Работа с Рутокен с NFC завершена")
                }
            }

            let token: Token

            if isNFC {
                try startNfc(withWaitMessage: "Поднесите Рутокен с NFC", workMessage: "Рутокен с NFC подключен, идет обмен данными...")
                let nfcStopped = Future<Token?, Never> { promise in
                    Task { [weak self] in
                        self?.waitForNfcStop()
                        promise(.success((nil)))
                    }
                }.eraseToAnyPublisher()

                let nfcTokenFind = TokenManager.shared.tokens
                    .compactMap { $0.first(where: { $0.currentInterface == .NFC }) }
                    .map { Optional($0) }
                    .eraseToAnyPublisher()

                var nfcToken: Token?

                let waitNfcTokenAppearance = Publishers.Merge(nfcStopped, nfcTokenFind).sink { [unowned self] card in
                    nfcToken = card
                    semaphore.signal()
                }

                semaphore.wait()
                waitNfcTokenAppearance.cancel()
                guard let nfcToken else {
                    throw TokenManagerError.tokenNotFound
                }
                token = nfcToken
            } else {
                guard let connectedToken = state.tokens.first(where: { $0.serial == state.selectedTokenSerial }) else {
                    throw TokenError.tokenDisconnected
                }
                token = connectedToken
            }

            try token.login(pin: pin)
            defer {
                token.logout()
            }
            let certs = try token.enumerateCerts()
            DispatchQueue.main.async { [unowned self] in
                state.selectedTokenSerial = token.serial
                state.selectedTokenType = token.currentInterface
                state.selectedTokenInterfaces = token.supportedInterfaces
                state.selectedTokenCerts = certs
                state.sheetType = state.sheetType != nil ? .certList : nil
            }
        } catch TokenError.incorrectPin {
            self.setErrorMessage(message: "Неверный PIN-код")
        } catch TokenError.lockedPin {
            self.setErrorMessage(message: "Превышен лимит ошибок при вводе PIN-кода")
        } catch TokenError.tokenDisconnected {
            self.setErrorMessage(message: "Потеряно соединение с Рутокеном")
        } catch TokenManagerError.tokenNotFound, ReaderError.timeout {
            setErrorMessage(message: "Рутокен не обнаружен. Для продолжения работы подключите Рутокен к устройству")
        } catch ReaderError.readerUnavailable {
            self.setErrorMessage(message: "Не удалось обнаружить считыватель")
        } catch ReaderError.cancelledByUser {
        } catch {
            self.setErrorMessage(message: "Что-то пошло не так. Попробуйте повторить операцию")
        }
    }

    private func waitForNfcStop() {
        guard let reader = state.readers.first(where: {$0.type == .vcr || $0.type == .nfc }) else {
            return
        }
        try? pcscWrapper.waitForExchangeIsOver(withReader: reader.name)
    }

    private func startNfc(withWaitMessage waitMessage: String, workMessage: String) throws {
        guard let reader = state.readers.first(where: {$0.type == .vcr || $0.type == .nfc }) else {
            throw ReaderError.readerUnavailable
        }
        try pcscWrapper.startNfc(onReader: reader.name, waitMessage: waitMessage, workMessage: workMessage)
    }

    private func stopNfc(withMessage message: String) throws {
        guard let reader = state.readers.first(where: {$0.type == .vcr || $0.type == .nfc }) else {
            throw ReaderError.readerUnavailable
        }
        try pcscWrapper.stopNfc(onReader: reader.name, withMessage: message)
    }

    private func setErrorMessage(message: String) {
        DispatchQueue.main.async {
            self.state.taskStatus.errorMessage = message
        }
    }
}
