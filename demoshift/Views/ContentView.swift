//
//  ContentView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var showTokenListView = false
    @State var showSignView = false

    @State var selectedUser: User?

    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: User.getAllUsers()) var users: FetchedResults<User>

    init() {
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = UIColor(named: "view-background")
        UITableViewCell.appearance().backgroundColor = UIColor(named: "view-background")
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

                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Image("Logo")
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
                        }
                        .animation(.easeInOut)
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
