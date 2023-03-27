//
//  UserListView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import Combine
import SwiftUI


struct UserListView: View {
    @EnvironmentObject var routingState: RoutingState
    @State var selectedUser: User?

    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: TokenListView(),
                               isActive: self.$routingState.showTokenListView) {
                    EmptyView()
                }
                .isDetailLink(false)

                NavigationLink(destination: SignView(user: self.selectedUser),
                               isActive: self.$routingState.showSignView) {
                    EmptyView()
                }
                .isDetailLink(false)
                NavigationLink(destination: VcrListView(),
                               isActive: self.$routingState.showVCRListView) {
                    EmptyView()
                }
                .isDetailLink(false)

                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Image("logo")
                        Spacer()
                    }
                    .padding(.top)

                    if self.users.isEmpty {
                        Spacer()
                        Text("Нет доступных пользователей")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            ForEach(users) { user in
                                UserCard(user: user, selectUser: {
                                    selectedUser = user
                                    routingState.showSignView.toggle()
                                }, removeUser: {
                                    managedObjectContext.delete(user)
                                    do {
                                        try managedObjectContext.save()
                                    } catch {
                                        // Handle error here
                                    }
                                })
                                .padding(.top)
                                .padding(.vertical)
                                .padding(.horizontal, 24)
                            }
                        }
                        .animation(.easeInOut)
                    }
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        HStack(alignment: .center) {
                            Button {
                                self.routingState.showVCRListView.toggle()
                            } label: {
                                Text("Подключить виртуальный считыватель")
                                    .foregroundColor(Color("text-blue"))
                                    .multilineTextAlignment(.center)
                            }
                            HintButton(popoverView: {
                                Hint(titlePopover: "Виртуальный считыватель",
                                     plainText: ["Если на вашем мобильном устройстве нет NFC модуля, " +
                                                 "то вы можете использовать виртуальный считыватель."],
                                     titleBulletText: "Для работы с виртуальным считывателем:",
                                     bulletText: ["Установите приложение Рутокен VCR на iPhone",
                                                  "Нажмите «Подключить виртуальный считыватель»",
                                                  "В правом нижнем углу нажмите на плюс",
                                                  "Отсканируйте QR-код с экрана iPad",
                                                  "Приложите Рутокен с NFC к модулю NFC вашего iPhone"])
                            })

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Button(action: {
                        self.routingState.showTokenListView.toggle()
                    }, label: {
                        Text("Добавить пользователя")
                    })
                        .buttonStyle(RoundedFilledButton())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationBarTitle("Пользователи", displayMode: .inline)
            .background(Color("view-background").edgesIgnoringSafeArea(.all))
        }
        .navigationViewStyle(.stack)
    }
}
