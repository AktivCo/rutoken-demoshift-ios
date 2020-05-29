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

    @ObservedObject private var taskStatus = TaskStatus()

    var body: some View {
        VStack {
            Text("Документ для подписи")
                .fontWeight(.semibold)
                .font(.headline)

            Image("document").resizable()
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
                                            }
                                        }
                                    }
                    })
                })
        }
        .padding()
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
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
