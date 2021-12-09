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
            QrCode(qrCode: Image(uiImage: state.qrCode ?? UIImage(systemName: "qrcode")!), isBlur: state.isBlurQr)
            Spacer()
            Text("время действия QR-кода")
                .padding(.bottom)
            Text(state.currentTime ?? "--:--")
                .foregroundColor(Color.red)
                .font(.system(.title, design: .monospaced))
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
        .onDisappear(perform: {
            interactor.stopQrTimer()
        })
    }
}
