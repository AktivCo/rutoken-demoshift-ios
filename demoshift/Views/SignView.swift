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
    @State var signatureToShare: SharableSignature?
    @State var documentToShare: SharableDocument?

    let user: User
    let url: URL?

    @ObservedObject private var taskStatus = TaskStatus()

    init(user: User) {
        self.user = user

        let urls = Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: "")
        if urls != nil && urls!.count > 0 {
            self.url = urls![0]
        } else {
            self.url = nil
        }
    }

    var body: some View {
        VStack {
            NavigationLink(destination: SignResultView(document: documentToShare, signature: signatureToShare),
                           isActive: self.$showSignResultView) {
                EmptyView()
            }

            Text("Документ для подписи")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top)

            HStack {
                if self.url != nil {
                    DocumentView(self.url!)
                } else {
                    Text("Не удалось найти документ")
                }
            }
            .padding()
            Spacer()
            Button(action: {
                self.showSignView.toggle()
            }, label: {
                Text("Подписать")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .disabled(self.url == nil)
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
                                                throw TokenManagerError.tokenNotFound
                                            }
                                            guard token.serial == self.user.tokenSerial else {
                                                throw TokenManagerError.wrongToken
                                            }

                                            let document = try Data(contentsOf: self.url!)

                                            try token.login(pin: pin)

                                            let signature = try token.cmsSign(document, withCert: Cert(id: self.user.certID, body: self.user.certBody))

                                            // For correct work with AirDrop all sharable items should be in the same folder
                                            let cmsFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(self.url!.lastPathComponent).sig")
                                            let signedFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(self.url!.lastPathComponent)")

                                            do {
                                                try signature.write(to: cmsFile, atomically: false, encoding: .utf8)
                                                try document.write(to: signedFile)
                                            } catch {
                                                throw TokenError.generalError
                                            }

                                            self.signatureToShare = SharableSignature(rawSignature: signature, cmsFile: cmsFile)
                                            self.documentToShare = SharableDocument(signedFile: signedFile)

                                            DispatchQueue.main.async {
                                                self.showSignView = false
                                                self.showSignResultView.toggle()
                                            }
                                        } catch TokenError.incorrectPin {
                                            self.setErrorMessage(message: "Неверный PIN-код")
                                        } catch TokenError.lockedPin {
                                            self.setErrorMessage(message: "PIN-код заблокирован")
                                        } catch TokenManagerError.tokenNotFound {
                                            self.setErrorMessage(message: "Не удалось обнаружить токен")
                                        } catch TokenError.keyPairNotFound {
                                            self.setErrorMessage(message: "Ключевая пара не найдена")
                                        } catch TokenManagerError.wrongToken {
                                            self.setErrorMessage(message: "Поднесен токен другого пользователя")
                                        } catch {
                                            self.setErrorMessage(message: "Что-то пошло не так")
                                        }
                                    }
                    })
                })
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
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
            SignView(user: User(fromCert: Cert(id: Data(), body: Data()), tokenSerial: "")).environment(\.colorScheme, .light)
            SignView(user: User(fromCert: Cert(id: Data(), body: Data()), tokenSerial: "")).environment(\.colorScheme, .dark)
        }
    }
}
