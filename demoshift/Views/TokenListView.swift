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
            .padding(.bottom, 10)
        VStack(alignment: .center, spacing: 0) {
            if state.tokens.isEmpty {
                Text("Рутокены не обнаружены.")
                    .font(.system(size: 16))
                    .foregroundColor(Color("text-gray"))
                    .frame(height: 106)
                    .padding(.bottom, 20)
                Text("Для работы с устройствами Рутокен ЭЦП 2.0 и 3.0 по USB требуется iOS 16.2 и новее")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 16))
                    .foregroundColor(Color("text-gray"))
                    .padding(.horizontal, 20)
            } else {
                getTokenItems()
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
