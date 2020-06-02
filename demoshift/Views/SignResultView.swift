//
//  SignResultView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct SignResultView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    @State var signature = "i'm pem encoded cms"

    var body: some View {
        VStack {
            Text("\(self.signature)")
                .padding()
            Spacer()
            Button(action: {
                UIPasteboard.general.string = self.signature
            }, label: {
                Text("Скопировать")
            })
            .buttonStyle(RoundedFilledButton())
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Подпись документа", displayMode: .inline)
    }
}

struct SignResultView_Previews: PreviewProvider {
    static var previews: some View {
        SignResultView()
    }
}
