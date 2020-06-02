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

    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    var body: some View {
        VStack {
            NavigationLink(destination: SignResultView(), isActive: self.$showSignResultView) {
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
                                    // Imagine we call pkcs11 here
                                    self.taskStatus.errorMessage = ""
                                    withAnimation(.spring()) {
                                        self.taskStatus.isInProgress = true
                                    }
                                    DispatchQueue.global(qos: .default).async {
                                        sleep(2) //Do login/find/whatever we want
                                        DispatchQueue.main.async {
                                            //Here we finished pkcs11 operation
                                            if pin == "12345678" {
                                                self.showSignView.toggle()
                                            } else {
                                                self.taskStatus.errorMessage = "Неверный PIN-код"
                                            }
                                            withAnimation(.spring()) {
                                                self.taskStatus.isInProgress = false
                                                self.showSignResultView.toggle()
                                            }
                                        }
                                    }
                    })
                })
        }
        .padding()
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Документ для подписи", displayMode: .inline)
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
