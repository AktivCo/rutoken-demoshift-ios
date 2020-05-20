//
//  ContentView.swift
//  demoshift
//
//  Created by Андрей Трифонов on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

class User: Identifiable {
    let name: String
    let position: String
    let company: String
    let expired: String

    init(name: String, position: String, company: String, expired: String) {
        self.name = name
        self.position = position
        self.company = company
        self.expired = expired
    }
}

var fakeUsers: [User] = [
    User(name: "Березуцкий Юрий Николаевич",
    position: "Самый главный специалист по мониторингу и прессингу важных специалистов, но чуть менее важных чем данный",
    company: "ООО «Экспресс-мед»",
    expired: "20 мая 2050 г."),

    User(name: "Пинский Виктор Витальевич",
    position: "Главный диспетчер",
    company: "ООО \"Самый большой и серьёзный бизнес, такой что не влезет ни в какие рамки\"",
    expired: "20 мая 2050 г."),

    User(name: "Барнаби Мармадюк Алоизий Бенджи Кобвеб Дартаньян Эгберт Феликс Гаспар Гумберт Игнатий Джейден Каспер Лерой Максимилиан Недди Объяхулу Пепин Кьюллиам Розенкранц Секстон Тедди Апвуд Виватма Уэйленд Ксилон Ярдли Закари Усански",
    position: "Главный бухгалтер",
    company: "ООО \"Клиник Эконом\", МедПрофСправки",
    expired: "20 мая 2050 г."),

    User(name: "Борисов Егор Афанасьевич",
    position: "Финансовый директор",
    company: "Evakuator-msk",
    expired: "20 мая 2050 г."),

    User(name: "Данчикова Галина Иннокентьевна",
    position: "Ведущий специалист военного представительства",
    company: "Общество с ограниченной ответственностью «Легион-Р» ",
    expired: "20 мая 2050 г."),

    User(name: "Николаев Николай Петрович",
    position: "Инженер по буровым работам",
    company: "Пластический хирург Петрин Сергей Александрович",
    expired: "20 мая 2050 г.")
]

struct ContentView: View {
    @State var users: [User] = []
    @State var showAddUserView = false

    @ObservedObject private var taskStatus = TaskStatus()

    var body: some View {
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
                    Text("Выберите пользователя")
                        .fontWeight(.semibold)
                        .font(.title)
                        .padding(.leading)
                        .padding(.top)

                    List(self.users) {user in
                        UserView(name: user.name, position: user.position, company: user.company, expired: user.expired)
                    }
                    .animation(.easeInOut)
                }
                Button(action: {
                    self.showAddUserView.toggle()
                }, label: {
                    HStack {
                        Spacer()
                        Text("Добавить пользователя")
                        Spacer()
                    }
                })
                .buttonStyle(RoundedFilledButton())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                    .sheet(isPresented: self.$showAddUserView, onDismiss: {
                        self.taskStatus.errorMessage = ""
                    }, content: {
                        PinInputView(idleTitle: "Введите PIN-код",
                                    progressTitle: "Выполнятеся регистрация пользователя",
                                    placeHolder: "PIN-код",
                                    buttonText: "Продолжить",
                                    status: self.taskStatus,
                                    onTapped: { pin in
                                        // Imagine we call pkcs11 here
                                        self.taskStatus.errorMessage = ""
                                        withAnimation(.spring()) {
                                            self.taskStatus.isInProgress = true
                                        }
                                        DispatchQueue.global(qos: .default).async {
                                            sleep(2) //Do login/find/whatever we want
                                            DispatchQueue.main.async {
                                                //Here we finished pkcs11 operation
                                                if pin == "12345678" {
                                                    self.showAddUserView.toggle()
                                                    self.addUser(idx: self.users.count)
                                                } else {
                                                    self.taskStatus.errorMessage = "Неверный PIN-код"
                                                }
                                                withAnimation(.spring()) {
                                                    self.taskStatus.isInProgress = false
                                                }
                                            }
                                        }
                        })
                })
            }
        }.background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    func addUser(idx: Int) {
        if idx < fakeUsers.count {
            users.append(fakeUsers[idx])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.colorScheme, .light)
            ContentView().environment(\.colorScheme, .dark)
        }
    }


}
