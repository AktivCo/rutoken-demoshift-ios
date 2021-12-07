//
//  VcrListView.swift
//  demoshift
//
//  Created by Александр Иванов on 21.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct VcrListView: View {
    @State var showAddVcrView = false

    var body: some View {
        NavigationLink(destination: AddVcrView(),
                       isActive: self.$showAddVcrView) {
            EmptyView()
        }
        .isDetailLink(false)

        ZStack {
            VStack {
                HStack(alignment: .center) {
                    Text("Доступные считыватели")
                        .font(.headline)
                    HintButton(popoverView: {
                        Hint(titlePopover: "Работа с виртуальными считывателями",
                             plainText: ["На этом экране вы можете добавить, удалить считыватель и посмотреть его статус.",
                                         "Подключение и отключение считывателей выполняются в приложении Рутокен VCR на вашем iPhone."],
                             titleBulletText: "Чтобы включить/отключить считыватель:",
                             bulletText: ["На iPhone откройте приложение Рутокен VCR.",
                                          "Найдите карточку с именем вашего \"\(UIDevice.current.name)\" " +
                                          "и названием приложения \"\(getAppName())\".",
                                          "Под этой карточкой нажмите на кнопку Подключить/Отключить."])
                    })
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
                List {
                    VCRCard(name: "iPhone (Sasha) - VCR", isActive: false)
                    VCRCard(name: "iPhone (Masha) - VCR", isActive: true)
                    VCRCard(name: "iPhone (Ragnaros) - VCR", isActive: false)
                    VCRCard(name: "iPhone (Stas) - VCR", isActive: true)
                    VCRCard(name: "iPhone (SAS) - VCR", isActive: false)
                }
            }
            VStack(alignment: .trailing) {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAddVcrView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .font(.system(size: 80))
                            .foregroundColor(Color("button-background"))
                            .background(Color("view-background").mask(Circle()).scaleEffect(0.8))
                    }
                }
                .padding(.bottom, 20)
                .padding(.trailing, 40)
            }
        }
        .background(Color("view-background").edgesIgnoringSafeArea(.all))
    }

    func getAppName() -> String {
        guard let dictionary = Bundle.main.infoDictionary,
              let name = dictionary["CFBundleName"] as? String else {
                  return "Client Application"
              }
        return name
    }

}
