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

    @EnvironmentObject var routingState: RoutingState
    @EnvironmentObject var state: SignState

    @State var wrappedUrl = AccessedUrl(Bundle.main.urls(forResourcesWithExtension: "pdf", subdirectory: "")?.first)
    @State var showDocumentPicker = false

    let user: User?

    var body: some View {
        VStack {
            NavigationLink(destination: SignResultView(document: state.documentToShare,
                                                       signature: state.signatureToShare),
                           isActive: self.$routingState.showSignResultView) {
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
                state.showPinInputView.toggle()
            }, label: {
                Text("Подписать")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .disabled(self.wrappedUrl == nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: self.$state.showPinInputView, onDismiss: {
                    self.state.taskStatus.errorMessage = ""
                }, content: {
                    PinInputView(idleTitle: "Введите PIN-код",
                                 progressTitle: "Выполняется подпись документа",
                                 placeHolder: "PIN-код",
                                 buttonText: "Продолжить",
                                 taskStatus: self.state.taskStatus,
                                 onTapped: { pin in
                        interactorsContainer.signInteractor?.sign(withPin: pin, forUser: user, wrappedUrl: wrappedUrl!)
                    })
                })
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }
}
