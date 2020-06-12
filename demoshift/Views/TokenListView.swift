//
//  TokenListView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct TokenListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    @Binding var isPresent: Bool
    @State var showPinInputView = true

    @ObservedObject private var taskStatus = TaskStatus()

    var body: some View {
        VStack {
            Text("Выберите Рутокен")
                .font(.headline)
                .padding(.top)
            List {
                VStack {
                    HStack(alignment: .top) {
                        Text("Подключить NFC карту")
                            .font(.headline)
                        Spacer()
                        Image("gray-nfc-icon")
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color("listitem-background"))
                .cornerRadius(15)
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

                                        startNFC { _ in
                                            TokenManager.shared.cancelWait()
                                        }
                                        defer {
                                            stopNFC()
                                        }

                                        do {
                                            guard let token = TokenManager.shared.waitForToken() else {
                                                throw TokenManagerError.tokenNotFound
                                            }
                                            guard self.isTokenNotUsed(serial: token.serial) else {
                                                throw TokenManagerError.wrongToken
                                            }

                                            try token.login(pin: pin)

                                            let certs = try token.enumerateCerts()
                                            guard certs.count != 0 else {
                                                throw TokenError.certNotFound
                                            }

                                            guard User.makeUser(forCert: certs[0], withTokenSerial: token.serial, context: self.managedObjectContext) != nil else {
                                                throw TokenError.generalError
                                            }
                                            try self.managedObjectContext.save()

                                            DispatchQueue.main.async {
                                                self.showPinInputView.toggle()
                                                self.isPresent.toggle()
                                            }
                                        } catch TokenError.incorrectPin {
                                            self.setErrorMessage(message: "Неверный PIN-код")
                                        } catch TokenError.lockedPin {
                                            self.setErrorMessage(message: "Превышен лимит ошибок при вводе PIN-кода")
                                        } catch TokenError.certNotFound {
                                            self.setErrorMessage(message: "На Рутокене нет сертификатов")
                                        } catch TokenError.tokenDisconnected {
                                            self.setErrorMessage(message: "Потеряно соединение с Рутокеном")
                                        } catch TokenManagerError.tokenNotFound {
                                            self.setErrorMessage(message: "Не удалось обнаружить Рутокен")
                                        } catch TokenManagerError.wrongToken {
                                            self.setErrorMessage(message: "Рутокен уже использован другим пользователем")
                                        } catch {
                                            self.setErrorMessage(message: "Что-то пошло не так. Попробуйте повторить операцию")
                                        }
                                    }
                    })
                })
            }
            Spacer()
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    func isTokenNotUsed(serial: String) -> Bool {
        for u in self.users where u.tokenSerial == serial {
            return false
        }
        return true
    }

    func setErrorMessage(message: String) {
        DispatchQueue.main.async {
            self.taskStatus.errorMessage = message
        }
    }
}
