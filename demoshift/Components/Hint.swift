//
//  Hint.swift
//  demoshift
//
//  Created by Александр Иванов on 20.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct Hint: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            Text("Виртуальный считыватель")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
                .padding(.vertical)
            Text("Если на вашем мобильном устройстве нет NFC модуля, " +
                 "то вы можете использовать виртуальный считыватель.")
            Text("Для работы с виртуальным считывателем:")
                .padding(.vertical)
            listElement("1.", "Установите приложение VCR на iPhone")
            listElement("2.", "Отсканируйте QR-код с экрана iPad")
            listElement("3.", "Приложите Рутокен с NFC к модулю NFC вашего iPhone")
                .padding(.bottom)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .background(Color("sheet-background").edgesIgnoringSafeArea(.all))
    }

    func listElement(_ bullet: String, _ text: String) -> some View {
            HStack(alignment: .top) {
                Text(bullet)
                    .font(.system(.body, design: .monospaced))
                Spacer().fixedSize()
                Text(text)
                    .padding(.leading)
            }
        }

}
