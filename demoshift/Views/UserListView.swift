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
    @State var showTokenListView = false
    @State var showSignView = false

    @State var selectedUser: User?

    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    init() {
        if #available(iOS 14.0, *) {} else {
            UITableView.appearance().separatorStyle = .none
        }

        UITableView.appearance().backgroundColor = UIColor(named: "view-background")
    }

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: TokenListView(isPresent: self.$showTokenListView),
                               isActive: self.$showTokenListView) {
                    EmptyView()
                }
                .isDetailLink(false)

                NavigationLink(destination: SignView(isPresent: self.$showSignView,
                                                     user: self.selectedUser),
                               isActive: self.$showSignView) {
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
                        List {
                            ForEach(users) { user in
                                UserCard(user: user)
                                    .padding(.top)
                                    .onTapGesture {
                                        self.selectedUser = user
                                        self.showSignView.toggle()
                                    }
                            }
                            .onDelete(perform: deleteUser)
                            .listRowBackground(Color("view-background"))
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
                                     bulletText: ["Установите приложение VCR на iPhone",
                                                  "Отсканируйте QR-код с экрана iPad",
                                                  "Приложите Рутокен с NFC к модулю NFC вашего iPhone"])
                            })

                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Button(action: {
                        self.showTokenListView.toggle()
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

    func deleteUser(at offsets: IndexSet) {
        for index in offsets {
            let man = users[index]
            managedObjectContext.delete(man)
            do {
                try self.managedObjectContext.save()
            } catch {
                // Handle error here 
            }
        }
    }
}
