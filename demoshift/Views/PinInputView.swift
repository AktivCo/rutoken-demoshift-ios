//
//  AddUserView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 19.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

let screen = UIScreen.main.bounds

class TaskStatus: ObservableObject {
    @Published public var errorMessage = ""
    @Published public var isInProgress = false
}

//This add ability to hide keybaord on demand
private extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PinInputView: View {
    let idleTitle: String
    let progressTitle: String
    let placeHolder: String
    let buttonText: String

    @State private var pin = ""

    @ObservedObject var status: TaskStatus

    let onTapped: (String) -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(self.idleTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 40)
                Text(self.status.errorMessage)
                    .font(.headline)
                    .foregroundColor(Color("red-text"))
                    .padding(.top, 40)
                TextFieldWithFloatingLabel(placeHolder: placeHolder, text: self.$pin)
                    .padding(.top)
                Button(action: {
                    UIApplication.shared.endEditing()
                    self.onTapped(self.pin)
                }, label: {
                    Text("\(self.buttonText)")
                })
                .buttonStyle(RoundedFilledButton())
                .padding(.top, 40)
                Spacer()
            }
            .padding()
            .offset(x: 0, y: self.status.isInProgress ? -screen.height : 0)
            .background(Color("sheet-background"))

            VStack {
                Text(self.progressTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                LoadingIndicatorView()
                    .frame(width: 64, height: 64)
            }
            .background(Color("sheet-background"))
            .offset(x: 0, y: self.status.isInProgress ? 0 : screen.height)
        }
        .background(Color("sheet-background").edgesIgnoringSafeArea(.all))
    }
}

struct PinInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PinInputView(idleTitle: "Для входа введите PIN-код",
                        progressTitle: "Подождите, выполняется вход",
                        placeHolder: "PIN-код",
                        buttonText: "Войти",
                        status: TaskStatus(),
                        onTapped: {_ in }).environment(\.colorScheme, .light)

            PinInputView(idleTitle: "Для входа введите PIN-код",
                        progressTitle: "Подождите, выполняется вход",
                        placeHolder: "PIN-код",
                        buttonText: "Войти",
                        status: TaskStatus(),
                        onTapped: {_ in }).environment(\.colorScheme, .dark)
        }
    }
}
