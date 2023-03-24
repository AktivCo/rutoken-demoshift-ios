//
//  SignInteractor.swift
//  demoshift
//
//  Created by Vova Badyaev on 29.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import Combine
import SwiftUI


enum CommonError: Error {
    case bluetoothIsOff
}

class SignInteractor {
    private let pcscWrapper: PcscWrapper
    private var routingState: RoutingState
    private var state: SignState

    private let btHelper: BluetoothHelper

    private let semaphore = DispatchSemaphore.init(value: 0)
    private var cancellable = Set<AnyCancellable>()

    init(state: SignState, routingState: RoutingState, _ pcscWrapper: PcscWrapper) {
        self.state = state
        self.routingState = routingState
        self.pcscWrapper = pcscWrapper
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .assign(to: \.readers, on: state)
            .store(in: &cancellable)
        TokenManager.shared.tokens()
            .receive(on: DispatchQueue.main)
            .assign(to: \.tokens, on: state)
            .store(in: &cancellable)

        self.btHelper = BluetoothHelper()
    }

    func sign(withPin pin: String, forUser choosenUser: User?, wrappedUrl: AccessedUrl?) {
        do {
            guard let choosenUser = choosenUser,
                  let wrappedUrl = wrappedUrl else {
                throw TokenError.generalError
            }

            var isNFC = false
            defer {
                if isNFC {
                    try? stopNfc(withMessage: "Работа с Рутокен с NFC завершена")
                }
            }

            let token: Token

            if let connectedToken = state.tokens.first(where: { $0.serial == choosenUser.tokenSerial }) {
                token = connectedToken
            } else if choosenUser.tokenSupportedInterfaces.contains(.NFC) {
                isNFC = true
                var nfcToken: Token?
                let cancellable = TokenManager.shared.tokens().sink { [unowned self] in
                    if let card = $0.first(where: { $0.currentInterface == .NFC }) {
                        nfcToken = card
                        semaphore.signal()
                    }
                }
                let welcomeMessage = choosenUser.tokenSupportedInterfaces.contains(.USB) ?
                "Поднесите Рутокен с NFC или отмените операцию и подключите Рутокен по USB" :
                "Поднесите Рутокен с NFC"
                try startNfc(withWaitMessage: welcomeMessage, workMessage: "Рутокен с NFC подключен, идет обмен данными...")
                _ = semaphore.wait(timeout: .now() + 2)
                guard let nfcToken else {
                    throw TokenManagerError.tokenNotFound
                }
                token = nfcToken
            } else if choosenUser.tokenSupportedInterfaces.contains(.BT),
                      btHelper.state.value != .poweredOn {
                throw CommonError.bluetoothIsOff
            } else {
                throw TokenManagerError.tokenNotFound
            }

            guard token.serial == choosenUser.tokenSerial else {
                throw TokenManagerError.wrongToken
            }
            try token.login(pin: pin)
            defer {
                token.logout()
            }

            guard let cert = Cert(id: choosenUser.certID, body: choosenUser.certBody) else {
                throw TokenError.generalError
            }

            let document = try Data(contentsOf: wrappedUrl.url)
            let signature = try token.cmsSign(document, withCert: cert)

            // For correct work with AirDrop all sharable items should be in the same folder
            let cmsFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(wrappedUrl.url.lastPathComponent).sig")
            let signedFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(wrappedUrl.url.lastPathComponent)")

            try signature.write(to: cmsFile, atomically: false, encoding: .utf8)
            try document.write(to: signedFile)

            let sign = SharableSignature(rawSignature: signature, cmsFile: cmsFile)
            let doc = SharableDocument(signedFile: signedFile)

            DispatchQueue.main.async { [unowned self] in
                state.signatureToShare = sign
                state.documentToShare = doc
                state.showPinInputView = false
                routingState.showSignResultView = true
            }
        } catch CommonError.bluetoothIsOff {
            setErrorMessage(message: "Рутокен не обнаружен, т.к Bluetooth выключен. Включите его или подключите токен по USB")
        } catch TokenError.incorrectPin {
            setErrorMessage(message: "Неверный PIN-код")
        } catch TokenError.lockedPin {
            setErrorMessage(message: "Превышен лимит ошибок при вводе PIN-кода")
        } catch TokenManagerError.tokenNotFound, ReaderError.timeout {
            setErrorMessage(message: "Рутокен не обнаружен. Для продолжения работы подключите Рутокен к устройству")
        } catch ReaderError.readerUnavailable {
            setErrorMessage(message: "Не удалось обнаружить считыватель")
        } catch TokenError.keyPairNotFound {
            setErrorMessage(message: "Не удалось найти ключи, соответствующие сертификату")
        } catch TokenError.tokenDisconnected {
            setErrorMessage(message: "Потеряно соединение с Рутокеном")
        } catch TokenManagerError.wrongToken {
            setErrorMessage(message: "Пользователь зарегистрирован с другим Рутокеном")
        } catch ReaderError.cancelledByUser {
        } catch {
            setErrorMessage(message: "Что-то пошло не так. Попробуйте повторить операцию")
        }
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
