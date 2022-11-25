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

    func getUsbTokenItems() -> some View {
        ForEach(state.tokens) { token in
            HStack(spacing: 0) {
                Image("usb")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color("text-red"))
                    .padding(.vertical, 28)
                    .padding(.leading, 28)
                VStack(alignment: .leading, spacing: 0) {
                    Text(token.modelName.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.bottom, 14)
                    Text("Серийный номер: \(token.serial)")
                        .font(.system(size: 16))
                        .fontWeight(.light)
                        .foregroundColor(Color("text-gray"))
                }
                .padding(.vertical, 27)
                .padding(.leading, 16)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 106, alignment: .leading)
            .background(Color("listitem-background"))
            .cornerRadius(30)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .onTapGesture {
                interactorsContainer.tokenListInteractor?.didSelectToken(token.serial, type: token.type)
            }
        }
    }
}
