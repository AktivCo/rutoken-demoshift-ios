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

    init(state: TokenListState, _ pcscWrapper: PcscWrapper) {
        self.state = state
        self.pcscWrapper = pcscWrapper

        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .assign(to: \.readers, on: state)
            .store(in: &cancellable)
    }

    func nfcReaderAvailable() {
        self.pcscWrapper.readers()
            .receive(on: DispatchQueue.main)
            .first { $0.contains(where: { $0.type == .nfc || $0.type == .vcr }) }
            .sink { [unowned self] _ in
                self.state.showPinInputView = true
            }
            .store(in: &cancellable)
    }

    func readCerts(withPin pin: String) {
        do {
            try startNfc(withWaitMessage: "Поднесите Рутокен с NFC", workMessage: "Рутокен с NFC подключен, идет обмен данными...")
            defer {
                try? stopNfc(withMessage: "Работа с Рутокен с NFC завершена")
            }

            let token = try TokenManager.shared.getToken()
            try token.login(pin: pin)

            let certs = try token.enumerateCerts()

            DispatchQueue.main.async { [unowned self] in
                state.selectedTokenSerial = token.serial
                state.selectedTokenCerts = certs
                state.showPinInputView = false
                state.showCertListView = true
            }
        } catch TokenError.incorrectPin {
            self.setErrorMessage(message: "Неверный PIN-код")
        } catch TokenError.lockedPin {
            self.setErrorMessage(message: "Превышен лимит ошибок при вводе PIN-кода")
        } catch TokenError.tokenDisconnected {
            self.setErrorMessage(message: "Потеряно соединение с Рутокеном")
        } catch TokenManagerError.tokenNotFound {
            self.setErrorMessage(message: "Не удалось обнаружить Рутокен")
        } catch ReaderError.readerUnavailable {
            self.setErrorMessage(message: "Не удалось обнаружить считыватель")
        } catch {
            self.setErrorMessage(message: "Что-то пошло не так. Попробуйте повторить операцию")
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
