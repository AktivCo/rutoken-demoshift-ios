//
//  AddVcrView.swift
//  demoshift
//
//  Created by Александр Иванов on 02.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct AddVcrView: View {
    @ObservedObject private var state: AddVcrState
    private let interactor: AddVcrInteractor

    init() {
        let state = AddVcrState()
        self.state = state
        self.interactor = AddVcrInteractor(state: state)
    }

    var body: some View {
        VStack {
            Text("Добавление считывателя")
                .font(.headline)
            Spacer()
            Text("Отсканируйте QR-код")
            Spacer()
            if let qr = state.qrCode {
                Image(uiImage: qr)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: max(UIScreen.main.bounds.height*0.4, UIScreen.main.bounds.width*0.4))
                    .background(Color(red: 0.8, green: 0.8, blue: 0.8).scaleEffect(1.1))
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: max(UIScreen.main.bounds.height/2, UIScreen.main.bounds.width/2))
                    .blur(radius: 20)
            }
            Spacer()
            Text("время действия QR-кода")
                .padding(.bottom)
            Text("1:56")
                .foregroundColor(Color.red)
                .font(.title)
            Spacer()
            Button(action: {
                interactor.loadQrCode()
            }, label: {
                Text("Сгенерировать новый QR-код")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear(perform: {
            interactor.loadQrCode()
        })
    }
}
