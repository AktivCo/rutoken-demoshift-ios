//
//  TokenListView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 08.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI


struct TokenListView: View {
    @Environment(\.interactorsContainer) var interactorsContainer: InteractorsContainer
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    @EnvironmentObject var state: TokenListState
    @EnvironmentObject var routingState: RoutingState

    var body: some View {
        VStack {
            Text("Выберите Рутокен")
                .font(.headline)
                .padding(.top)
            ScrollView {
                if !state.readers.contains(where: { $0.type == .nfc || $0.type == .vcr }) {
                    VStack {
                        Text("Если на вашем мобильном устройстве нет NFC модуля,\n " +
                             "вам необходимо подключить виртуальный считыватель.")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color("listitem-background"))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 2.5, y: 2.5) .padding(.horizontal)
                } else {
                    VStack {
                        HStack(alignment: .top) {
                            Text("Подключить Рутокен с NFC")
                                .font(.headline)
                            Spacer()
                            Image("nfc-icon-gray")
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxHeight: 200)
                    .background(Color("listitem-background"))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 2.5, y: 2.5) .padding(.horizontal)
                    .onTapGesture {
                        interactorsContainer.tokenListInteractor?.didSelectToken(type: .NFC)
                    }
                }
                Text("ПОДКЛЮЧЕННЫЕ РУТОКЕНЫ")
                    .padding()
                getUsbTokenItems()
                Spacer()
            }
            .background(EmptyView().sheet(isPresented: self.$state.showPinInputView, onDismiss: {
                self.state.showPinInputView = false
                self.state.taskStatus.errorMessage = ""
            }, content: {
                PinInputView(idleTitle: "Введите PIN-код",
                             progressTitle: "Выполняется регистрация пользователя",
                             placeHolder: "PIN-код",
                             buttonText: "Продолжить",
                             taskStatus: self.state.taskStatus,
                             onTapped: { pin in
                    interactorsContainer.tokenListInteractor?.readCerts(withPin: pin)
                })
            }))
            .background(EmptyView().sheet(isPresented: self.$state.showCertListView, onDismiss: {
                self.state.showCertListView = false
            }, content: {
                CertListView()
            }))
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    func getInterfaceIcon(_ type: TokenType) -> some View {
        switch type {
        case .USB:
            return Image(systemName: "cable.connector.horizontal")
        case .NFC:
            return Image(systemName: "wave.3.backward.circle")
        case .BT:
            return Image(systemName: "point.3.connected.trianglepath.dotted")
        }
    }

    func getUsbTokenItems() -> some View {
        ForEach(state.tokens) { token in
            VStack {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(token.modelName.rawValue)
                            .font(.headline)
                        Text("Серийный номер: \(token.serial)")
                            .font(.footnote)
                        HStack {
                            ForEach(token.interfaces, id: \.self) { interface in
                                Group {
                                    getInterfaceIcon(interface)
                                    Text(interface.rawValue)
                                        .font(.footnote)
                                }
                                .foregroundColor(interface == token.type ? Color.blue: nil)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "person.badge.key.fill")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Spacer()
            }
            .padding()
            .frame(maxHeight: 80)
            .background(Color("listitem-background"))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 2.5, y: 2.5) .padding(.horizontal)
            .onTapGesture {
                interactorsContainer.tokenListInteractor?.didSelectToken(token.serial, type: token.type)
            }
        }
    }
}
