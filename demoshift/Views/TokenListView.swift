//
//  TokenListView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct TokenListView: View {
    @Environment(\.interactorsContainer) var interactorsContainer: InteractorsContainer
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    @Binding var isPresent: Bool
    @State var showPinInputView = true

    @State var showCertListView = false
    @State var selectedTokenSerial = ""
    @State var selectedTokenCerts: [Cert] = []

    @ObservedObject private var taskStatus = TaskStatus()

    var body: some View {
        VStack {
            Text("Выберите Рутокен")
                .font(.headline)
                .padding(.top)
            List {
                NavigationLink(destination: CertListView(isParentPresent: self.$isPresent,
                                                         tokenSerial: self.selectedTokenSerial,
                                                         certs: self.selectedTokenCerts),
                               isActive: self.$showCertListView) {
                    VStack {
                        HStack(alignment: .top) {
                            Text("Подключить Рутокен с NFC")
                                .font(.headline)
                            Spacer()
                            Image("nfc-icon-gray")
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color("listitem-background"))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.top)
                    .onTapGesture {
                        self.showPinInputView.toggle()
                    }
                    .sheet(isPresented: self.$showPinInputView, onDismiss: {
                        self.taskStatus.errorMessage = ""
                    }, content: {
                        PinInputView(idleTitle: "Введите PIN-код",
                                     progressTitle: "Выполняется регистрация пользователя",
                                     placeHolder: "PIN-код",
                                     buttonText: "Продолжить",
                                     status: self.taskStatus,
                                     onTapped: { pin in
                                        self.taskStatus.errorMessage = ""
                                        withAnimation(.spring()) {
                                            self.taskStatus.isInProgress = true
                                        }

                                        DispatchQueue.global(qos: .default).async {
                                            defer {
                                                DispatchQueue.main.async {
                                                    withAnimation(.spring()) {
                                                        self.taskStatus.isInProgress = false
                                                    }
                                                }
                                            }

                                            do {
                                                try interactorsContainer.pcscWrapperInteractor?
                                                    .startNfc(withWaitMessage: "Поднесите Рутокен с NFC",
                                                              workMessage: "Рутокен с NFC подключен, идет обмен данными...")
                                                defer {
                                                    interactorsContainer.pcscWrapperInteractor?.stopNfc(withMessage:
                                                                                                            "Работа с Рутокен с NFC завершена")
                                                }

                                                let token = try TokenManager.shared.getToken()

                                                self.selectedTokenSerial = token.serial

                                                try token.login(pin: pin)

                                                self.selectedTokenCerts = try token.enumerateCerts()

                                                DispatchQueue.main.async {
                                                    self.showPinInputView = false
                                                    self.showCertListView = true
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
                        })
                    })
                }
                .isDetailLink(false)
                .listRowBackground(Color("view-background"))
            }

            Spacer()
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    func setErrorMessage(message: String) {
        DispatchQueue.main.async {
            self.taskStatus.errorMessage = message
        }
    }
}
