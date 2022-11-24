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
    @EnvironmentObject var routingState: RoutingState

    @EnvironmentObject var state: TokenListState

    var body: some View {
        VStack(alignment: .leading) {
            if self.state.selectedTokenCerts.isEmpty {
                Spacer()
                Text("На Рутокене нет сертификатов")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.headline)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(self.state.selectedTokenCerts) { cert in
                        CertCard(cert: cert, isDisabled: self.isCertUsed(certBody: cert.body))
                            .padding(.top)
                            .onTapGesture {
                                if self.isCertUsed(certBody: cert.body) {
                                    return
                                }
                                guard User.makeUser(forCert: cert,
                                                    withTokenSerial: self.state.selectedTokenSerial,
                                                    tokenInterfaces: self.state.selectedTokenInterfaces,
                                                    context: self.managedObjectContext) != nil else {
                                    return
                                }
                                guard (try? self.managedObjectContext.save()) != nil else {
                                    return
                                }
                                self.state.showCertListView = false
                                self.routingState.showTokenListView = false
                            }
                    }
                    .listRowBackground(Color("view-background"))
                }
            }
        }
        .onAppear(perform: {
            UITableView.appearance().separatorStyle = .none
        })
    }

    func isCertUsed(certBody: Data) -> Bool {
        for u in self.users where u.certBody == certBody {
            return true
        }
        return false
    }
}
