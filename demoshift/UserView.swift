//
//  UserView.swift
//  demoshift
//
//  Created by Pavel Kamenov on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI

struct UserView: View {
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

    func field(caption: String, text: String) -> some View {
        Group {
            Text(caption)
                .font(.system(size: 20))
                .padding(.bottom, 2)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color(.systemGray))
                .padding(.horizontal, 10)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .fontWeight(.semibold)
                .font(.system(size: 20))

            field(caption: "Должность", text: position)
            field(caption: "Организация", text: company)
            field(caption: "Сертификат истекает", text: expired)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding()
        .background(Color("listitem-background"))
        .cornerRadius(15)
        .shadow(color: Color(.systemGray), radius: 5, x: 0, y: 0)
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(name: "Барнаби Мармадюк Алоизий Бенджи Кобвеб Дартаньян Эгберт Феликс Гаспар Гумберт Игнатий Джейден Каспер Лерой Максимилиан Недди Объяхулу Пепин Кьюллиам Розенкранц Секстон Тедди Апвуд Виватма Уэйленд Ксилон Ярдли Закари Усански", position: "Самый главный специалист по мониторингу и прессингу важных специалистов, но чуть менее важных чем данный", company: "ООО \"Самый большой и серьёзный бизнес, такой что не влезет ни в какие рамки\"", expired: "25 марта 2051")
    }
}
