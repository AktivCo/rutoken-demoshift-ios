//
//  SignView.swift
//  demoshift
//
//  Created by aktiv on 24.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct SignView: View {
    @State var showSignView = false
    @State var showSignResultView = false
    @State var urls = Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: "")

    @ObservedObject private var taskStatus = TaskStatus()

    @State var signature = ""

    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    var body: some View {
        VStack {
            NavigationLink(destination: SignResultView(signature: self.signature), isActive: self.$showSignResultView) {
                EmptyView()
            }

            if self.urls != nil {
                DocumentView(urls![0])
            } else {
                Text("Не удалось найти документ")
            }
            Spacer()
            Button(action: {
                self.showSignView.toggle()
            }, label: {
                Text("Подписать")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: self.$showSignView, onDismiss: {
                    self.taskStatus.errorMessage = ""
                }, content: {
                    PinInputView(idleTitle: "Введите PIN-код",
                                 progressTitle: "Выполняется подпись документа",
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
                                                throw TokenError.tokenNotFound
                                            }

                                            let document = try Data(contentsOf: (self.urls?[0])!)

                                            try token.login(pin: pin)
                                            let certs = try token.enumerateCerts()

                                            guard certs.count > 0 else {
                                                throw TokenError.certNotFound
                                            }

                                            self.signature = try token.cmsSign(document, withCert: certs[0])

                                            DispatchQueue.main.async {
                                                self.showSignView = false
                                                self.showSignResultView.toggle()
                                            }
                                        } catch TokenError.incorrectPin {
                                            self.setErrorMessage(message: "Неверный PIN-код")
                                        } catch TokenError.lockedPin {
                                            self.setErrorMessage(message: "PIN-код заблокирован")
                                        } catch TokenError.tokenNotFound {
                                            self.setErrorMessage(message: "Не удалось обнаружить токен")
                                        } catch TokenError.keyPairNotFound {
                                            self.setErrorMessage(message: "Ключевая пара не найдена")
                                        } catch TokenError.certNotFound {
                                            self.setErrorMessage(message: "Сертификат не найден")
                                        } catch {
                                            self.setErrorMessage(message: "Что-то пошло не так")
                                        }
                                    }
                    })
                })
        }
        .padding()
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Документ для подписи", displayMode: .inline)
    }

    func setErrorMessage(message: String) {
        DispatchQueue.main.async {
            self.taskStatus.errorMessage = message
        }
    }
}

struct SignView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignView().environment(\.colorScheme, .light)
            SignView().environment(\.colorScheme, .dark)
        }
    }
}
