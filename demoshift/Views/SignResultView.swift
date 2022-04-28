//
//  SignResultView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 02.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct SignResultView: View {
    @EnvironmentObject var routingState: RoutingState
    @State var showShareView = false

    let document: SharableDocument?
    let signature: SharableSignature?

    var body: some View {
        VStack {
            Spacer()

            Image("icon-ok")
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
                .padding(.top)
                .padding(.horizontal)
                .disabled(self.document == nil || self.signature == nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sheet(isPresented: $showShareView) {
                    ShareView(activityItems: [self.document!, self.signature!])
                }

            Button(action: {
                self.routingState.showSignResultView = false
                self.routingState.showSignView = false
            }, label: {
                Text("К списку пользователей")
            })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }
}
