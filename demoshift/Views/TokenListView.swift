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
            NavigationLink(destination: VcrListView(),
                           isActive: self.$routingState.showStackedAddVCRView) {
                EmptyView()
            }.isDetailLink(false)
            Text("Выберите Рутокен")
                .font(.headline)
                .padding(.top, 22)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if !state.readers.contains(where: { $0.type == .nfc || $0.type == .vcr }) {
                        Button {
                            self.routingState.showStackedAddVCRView.toggle()
                        } label: {
                            Text("Для подключения Рутокена с NFC используйте виртуальный считыватель")
                                .font(.system(size: 16))
                                .foregroundColor(Color("text-blue"))
                                .padding(.top, 98)
                                .padding(.bottom, 96)
                        }
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
                    tokenList()
                    Spacer()
                }
            }
            .padding(.top, 22)
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
        .padding(.horizontal, 20)
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    func tokenList() -> some View {
        Text("ПОДКЛЮЧЕННЫЕ РУТОКЕНЫ")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 32)
        VStack(alignment: .center, spacing: 0) {
            if #unavailable(iOS 16.0) {
                Text("Для работы с устройствами Рутокен ЭЦП 2.0 и 3.0 требуется iOS 16 и новее")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 66)
            } else if state.tokens.isEmpty {
                Text("Нет доступных устройств. Подключите Рутокен контактно и он отобразится в этом разделе")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 66)
            } else {
                getTokenItems()
                    .padding(.top, 10)
                if !state.tokens.contains(where: { $0.currentInterface == .BT }) {
                    Text("""
                    Для работы с Bluetooth-токеном включите Bluetooth и дайте приложению разрешение на его использование.\n
                    Также необходимо связать Рутокен с устройством через приложение Рутокен 3.0 BT
                    """)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                }
            }
        }
    }

    @ViewBuilder
    func getTokenItems() -> some View {
        VStack(spacing: 0) {
            ForEach(state.tokens) { token in
                TokenCard(modelName: token.modelName,
                          serial: token.serial,
                          currentInterface: token.currentInterface,
                          interfaces: token.supportedInterfaces)
                .allowsHitTesting(token.modelName != .unsupported)
                .onTapGesture {
                    interactorsContainer.tokenListInteractor?.didSelectToken(token.serial, type: token.currentInterface)
                }
                .padding(.bottom, 10)
            }
        }
    }
}
