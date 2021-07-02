//
//  CertListView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 09.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct CertListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    @Binding var isParentPresent: Bool

    @State var tokenSerial: String
    @State var certs: [Cert]

    var body: some View {
        VStack(alignment: .leading) {
            if self.certs.isEmpty {
                Spacer()
                Text("На Рутокене нет сертификатов")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(self.certs) { cert in
                        CertCard(cert: cert, isDisabled: self.isCertUsed(certBody: cert.body))
                            .padding(.top)
                            .onTapGesture {
                                if  self.isCertUsed(certBody: cert.body) {
                                    return
                                }
                                guard User.makeUser(forCert: cert, withTokenSerial: self.tokenSerial, context: self.managedObjectContext) != nil else {
                                    return
                                }
                                guard (try? self.managedObjectContext.save()) != nil else {
                                    return
                                }
                                self.isParentPresent = false
                        }
                        .padding()
                    }
                    .listRowBackground(Color("view-background"))
                    // Next two lines is workaround to remove list's separators in iOS 14+
                    .listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
                    .background(Color("view-background"))
                }
                .frame(width: screen.width)
                .animation(.easeInOut)
            }
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Выберите сертификат", displayMode: .inline)
    }

    func isCertUsed(certBody: Data) -> Bool {
        for u in self.users where u.certBody == certBody {
            return true
        }
        return false
    }
}
