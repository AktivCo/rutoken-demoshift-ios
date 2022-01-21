//
//  SignView.swift
//  demoshift
//
//  Created by aktiv on 24.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import PDFKit
import SwiftUI


struct SignView: View {
    @Environment(\.interactorsContainer) var interactorsContainer: InteractorsContainer

    @State var showPinInputView = false
    @State var showSignResultView = false
    @State var showDocumentPicker = false
    @State var signatureToShare: SharableSignature?
    @State var documentToShare: SharableDocument?

    @State var wrappedUrl = AccessedUrl(Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: "")?.first)

    @Binding var isPresent: Bool

    let user: User?

    @ObservedObject private var taskStatus = TaskStatus()

    var body: some View {
        VStack {
            NavigationLink(destination: SignResultView(isParentPresent: self.$isPresent,
                                                       document: documentToShare,
                                                       signature: signatureToShare),
                           isActive: self.$showSignResultView) {
                EmptyView()
            }
            .isDetailLink(false)

            Text("Документ для подписи")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top)

            Group {
                if self.wrappedUrl == nil {
                    Spacer()
                    Text("Файл не выбран")
                    Spacer()
                } else if self.wrappedUrl?.url.pathExtension != "pdf" {
                    Spacer()
                    Text("Не удалось отобразить файл")
                    Spacer()
                } else {
                    DocumentViewer(wrappedUrl: self.$wrappedUrl)
                }
            }
            .padding()

            Button(action: {
                self.showDocumentPicker.toggle()
            }, label: {
                Text("Выбрать файл")
            })
                .buttonStyle(RoundedFilledButton())
                .padding(.top)
                .padding(.horizontal)
                .sheet(isPresented: self.$showDocumentPicker, content: {
                    DocumentPickerView(wrappedUrl: self.$wrappedUrl)
                })

            Button(action: {
                self.showPinInputView.toggle()
            }, label: {
                Text("Подписать")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .disabled(self.wrappedUrl == nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: self.$showPinInputView, onDismiss: {
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

                                        do {
                                            guard let currentUser = self.user else {
                                                throw TokenError.generalError
                                            }

                                            try interactorsContainer.pcscWrapperInteractor?
                                                .startNfc(withWaitMessage: "Поднесите Рутокен с NFC",
                                                          workMessage: "Рутокен с NFC подключен, идет обмен данными...")
                                            defer {
                                                interactorsContainer.pcscWrapperInteractor?.stopNfc(withMessage:
                                                                                                        "Работа с Рутокен с NFC завершена")
                                            }

                                            let token = try TokenManager.shared.getToken()

                                            guard token.serial == currentUser.tokenSerial else {
                                                throw TokenManagerError.wrongToken
                                            }

                                            let document = try Data(contentsOf: self.wrappedUrl!.url)

                                            try token.login(pin: pin)

                                            guard let cert = Cert(id: currentUser.certID, body: currentUser.certBody) else {
                                                throw TokenError.generalError
                                            }

                                            let signature = try token.cmsSign(document, withCert: cert)

                                            // For correct work with AirDrop all sharable items should be in the same folder
                                            let cmsFile = FileManager.default.temporaryDirectory
                                                                            .appendingPathComponent("\(self.wrappedUrl!.url.lastPathComponent).sig")
                                            let signedFile = FileManager.default.temporaryDirectory
                                                                                .appendingPathComponent("\(self.wrappedUrl!.url.lastPathComponent)")

                                            do {
                                                try signature.write(to: cmsFile, atomically: false, encoding: .utf8)
                                                try document.write(to: signedFile)
                                            } catch {
                                                throw TokenError.generalError
                                            }

                                            self.signatureToShare = SharableSignature(rawSignature: signature, cmsFile: cmsFile)
                                            self.documentToShare = SharableDocument(signedFile: signedFile)

                                            DispatchQueue.main.async {
                                                self.showPinInputView = false
                                                self.showSignResultView = true
                                            }
                                        } catch TokenError.incorrectPin {
                                            self.setErrorMessage(message: "Неверный PIN-код")
                                        } catch TokenError.lockedPin {
                                            self.setErrorMessage(message: "Превышен лимит ошибок при вводе PIN-кода")
                                        } catch TokenManagerError.tokenNotFound {
                                            self.setErrorMessage(message: "Не удалось обнаружить Рутокен")
                                        } catch ReaderError.readerUnavailable {
                                            self.setErrorMessage(message: "Не удалось обнаружить считыватель")
                                        } catch TokenError.keyPairNotFound {
                                            self.setErrorMessage(message: "Не удалось найти ключи, соответствующие сертификату")
                                        } catch TokenError.tokenDisconnected {
                                            self.setErrorMessage(message: "Потеряно соединение с Рутокеном")
                                        } catch TokenManagerError.wrongToken {
                                            self.setErrorMessage(message: "Пользователь зарегистрирован с другим Рутокеном")
                                        } catch {
                                            self.setErrorMessage(message: "Что-то пошло не так. Попробуйте повторить операцию")
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
