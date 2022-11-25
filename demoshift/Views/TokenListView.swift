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
        VStack(alignment: .leading, spacing: 0) {
            Text("Выберите Рутокен")
                .font(.headline)
                .padding(.top, 22)
                .padding(.leading, 20)
            ScrollView(showsIndicators: false) {
                if !state.readers.contains(where: { $0.type == .nfc || $0.type == .vcr }) {
                    Text("Для подключения Рутокена с NFC используйте виртуальный считыватель")
                        .font(.system(size: 16))
                        .padding(.top, 98)
                        .padding(.bottom, 96)
                } else {
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 0) {
                            Text("Подключить Рутокен с NFC")
                                .font(.headline)
                                .padding(.top, 4)
                            Spacer()
                            Image("nfc-icon-gray")
                                .renderingMode(.original)
                                .resizable()
                                .frame(width: 138, height: 138, alignment: .center)
                        }
                        .padding(.vertical, 34)
                        .padding(.leading, 23)
                        .padding(.trailing, 20)
                        Spacer()
                    }
                    .frame(maxHeight: 213)
                    .background(Color("listitem-background"))
                    .cornerRadius(30)
                    .onTapGesture {
                        interactorsContainer.tokenListInteractor?.didSelectToken(type: .NFC)
                    }
                }
                usbTokenList()
                Spacer()
            }
            .padding(.top, 22)
            .padding(.horizontal, 20)
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

    @ViewBuilder
    func usbTokenList() -> some View {
        Text("ПОДКЛЮЧЕННЫЕ РУТОКЕНЫ")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
        if #unavailable(iOS 16.0) {
            Text("Для работы с устройствами Рутокен ЭЦП 2.0 и 3.0 требуется iOS 16 и новее")
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .padding(.horizontal, 20)
                .padding(.top, 66)
        } else {
            getUsbTokenItems()
        }
    }

    @ViewBuilder
    func getUsbTokenItems() -> some View {
        if state.tokens.isEmpty {
            VStack(alignment: .center, spacing: 0) {
                Text("Нет доступных устройств. Подключите Рутокен контактно и он отобразится в этом разделе")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 66)
            }
        }
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
            .onTapGesture {
                interactorsContainer.tokenListInteractor?.didSelectToken(token.serial, type: token.type)
            }
        }
        .padding(.vertical, 10)
    }
}
