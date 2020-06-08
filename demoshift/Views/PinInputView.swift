//
//  PinInputView.swift
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

    @Environment(\.presentationMode) var mode

    let onTapped: (String) -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(self.idleTitle)
                        .font(.title)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "xmark")
                    .font(.headline) // Change width of xmark - it is technically text
                    .foregroundColor(Color("blue-text"))
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .onTapGesture {
                        self.mode.wrappedValue.dismiss()
                    }
                }
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
                    .disabled(self.pin.count == 0)
                Spacer()
            }
            .padding()
            .offset(y: self.status.isInProgress ? -screen.height : 0)
            .background(Color("sheet-background"))

            VStack {
                VStack {
                    Text(self.progressTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    LoadingIndicator()
                        .frame(width: 64, height: 64)
                }
                .offset(y: -screen.height/4)
            }
            .background(Color("sheet-background"))
            .offset(y: self.status.isInProgress ? 0 : screen.height)
        }
        .background(Color("sheet-background").edgesIgnoringSafeArea(.all))
    }
}
