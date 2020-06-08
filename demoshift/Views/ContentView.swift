//
//  ContentView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var showPinInputView = false

    @ObservedObject private var taskStatus = TaskStatus()

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
                VStack(alignment: .leading) {
                    if self.users.isEmpty {
                        Spacer()
                        Text("Список пользователей пуст")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(users) { user in
                                NavigationLink(destination: SignView(user: user)) {
                                    UserCard(user: user)
                                        .padding(.top)
                                }
                            }
                            .onDelete(perform: deleteUser)
                            .navigationBarTitle("Пользователи", displayMode: .inline)
                        }
                        .animation(.easeInOut)
                    }
                    Button(action: {
                        self.showPinInputView.toggle()
                    }, label: {
                        Text("Добавить пользователя")
                    })
                        .buttonStyle(RoundedFilledButton())
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sheet(isPresented: self.$showPinInputView, onDismiss: {
                            self.taskStatus.errorMessage = ""
                        }, content: {
                            PinInputView(idleTitle: "Введите PIN-код",
                                         progressTitle: "Выполняется регистрация пользователя",
                                         placeHolder: "PIN-код",
                                         buttonText: "Продолжить",
                                         status: self.taskStatus,
                                         onTapped: { pin in
                                            self.taskStatus.errorMessage = ""
                                            withAnimation(.spring()) {
                                                self.taskStatus.isInProgress = true
                                            }

                                            DispatchQueue.global(qos: .default).async {
                                                defer {
                                                    DispatchQueue.main.async {
                                                        withAnimation(.spring()) {
                                                            self.taskStatus.isInProgress = false
                                                        }
                                                    }
                                                }

                                                startNFC { _ in
                                                    TokenManager.shared.cancelWait()
                                                }
                                                defer {
                                                    stopNFC()
                                                }

                                                do {
                                                    guard let token = TokenManager.shared.waitForToken() else {
                                                        throw TokenManagerError.tokenNotFound
                                                    }
                                                    guard self.isTokenNotUsed(serial: token.serial) else {
                                                        throw TokenManagerError.wrongToken
                                                    }

                                                    try token.login(pin: pin)

                                                    let certs = try token.enumerateCerts()
                                                    guard certs.count != 0 else {
                                                        throw TokenError.certNotFound
                                                    }

                                                    guard User.makeUser(forCert: certs[0], withTokenSerial: token.serial, context: self.managedObjectContext) != nil else {
                                                        throw TokenError.generalError
                                                    }
                                                    try self.managedObjectContext.save()

                                                    DispatchQueue.main.async {
                                                        self.showPinInputView.toggle()
                                                    }
                                                } catch TokenError.incorrectPin {
                                                    self.setErrorMessage(message: "Неверный PIN-код")
                                                } catch TokenError.lockedPin {
                                                    self.setErrorMessage(message: "PIN-код заблокирован")
                                                } catch TokenError.certNotFound {
                                                    self.setErrorMessage(message: "На токене нет сертификатов")
                                                } catch TokenError.tokenDisconnected {
                                                    self.setErrorMessage(message: "Потеряно соединение с токеном")
                                                } catch TokenManagerError.tokenNotFound {
                                                    self.setErrorMessage(message: "Не удалось обнаружить токен")
                                                } catch TokenManagerError.wrongToken {
                                                    self.setErrorMessage(message: "Токен уже использован")
                                                } catch {
                                                    self.setErrorMessage(message: "Что-то пошло не так")
                                                }
                                            }
                            })
                        })
                }
            }
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
            }
        }
    }

    func isTokenNotUsed(serial: String) -> Bool {
        for u in self.users where u.tokenSerial == serial {
            return false
        }
        return true
    }

    func setErrorMessage(message: String) {
        DispatchQueue.main.async {
            self.taskStatus.errorMessage = message
        }
    }
}
