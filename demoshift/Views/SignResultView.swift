//
//  SignResultView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct SignResultView: View {
    @State var showShareView = false

    let document: SharableDocument?
    let signature: SharableSignature?

    var body: some View {
        VStack {
            Spacer()

            Image("OkIcon")
                .padding()
            Text("Подпись успешно сформирована")
                .padding()

            Spacer()

            Button(action: {
                self.showShareView.toggle()
            }, label: {
                Text("Поделиться")
            })
            .buttonStyle(RoundedFilledButton())
            .padding()
            .disabled(self.document == nil || self.signature == nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showShareView) {
                ShareView(activityItems: [self.document!, self.signature!])
            }
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }
}

struct SignResultView_Previews: PreviewProvider {
    static var previews: some View {
        SignResultView(document: nil, signature: nil)
    }
}
