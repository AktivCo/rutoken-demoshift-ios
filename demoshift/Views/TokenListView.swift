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
                VStack(alignment: .center, spacing: 0) {
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
                        HStack(alignment: .top, spacing: 0) {
                            Text("Подключить Рутокен с NFC")
                                .font(.system(size: 17, weight: .medium))
                                .padding(.leading, 24)
                                .padding(.top, 32)
                            Spacer()
                            Image("nfc-icon-gray")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.top, 23)
                                .padding(.bottom, 10)
                                .padding(.trailing, 4)
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
            .sheet(isPresented: Binding<Bool>(get: { state.sheetType != nil },
                                              set: { if !$0 { interactorsContainer.tokenListInteractor?.dismissSheet() }}),
                   content: {
                switch state.sheetType {
                case .certList:
                    CertListView()
                default:
                    PinInputView(idleTitle: "Введите PIN-код",
                                 progressTitle: "Выполняется регистрация пользователя",
                                 placeHolder: "PIN-код",
                                 buttonText: "Продолжить",
                                 taskStatus: self.state.taskStatus,
                                 onTapped: { pin in
                        interactorsContainer.tokenListInteractor?.readCerts(withPin: pin)
                    })
                }})
        }
        .padding(.horizontal, 20)
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    func tokenList() -> some View {
        Text("ПОДКЛЮЧЕННЫЕ РУТОКЕНЫ")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
        VStack(alignment: .center, spacing: 0) {
            if #unavailable(iOS 16.0) {
                Text("Для работы с устройствами Рутокен ЭЦП 2.0 и 3.0 требуется iOS 16 и новее")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 66)
            } else if state.tokens.isEmpty {
                Group {
                    Text("Рутокены не обнаружены.")
                        .multilineTextAlignment(.center)
                        .padding(.top, 34)
                        .padding(.bottom, 40)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Если у вас USB-токен, то подключите его к мобильному устройству.")
                            .padding(.bottom, 16)
                        Text("Если у вас Bluetooth-токен, то:")
                            .padding(.bottom, 8)
                        BulletTextItem(bullet: "\u{2022}", text: "включите Bluetooth и дайте приложению разрешение на его использование;")
                            .padding(.bottom, 8)
                        BulletTextItem(bullet: "\u{2022}", text: "свяжите Рутокен с устройством через приложение Рутокен 3.0 BT.")
                            .padding(.bottom, 24)
                    }
                    Button {
                        if let url = URL(string: "rutokencp://"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            guard let url = URL(string: "http://itunes.apple.com/app/id1552392180") else {
                                return
                            }
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Подробнее")
                            .padding(.horizontal, 22)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2.5)
                                    .stroke(Color("text-gray"), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20.5)
                .font(.system(size: 16))
                .foregroundColor(Color("text-gray"))
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
