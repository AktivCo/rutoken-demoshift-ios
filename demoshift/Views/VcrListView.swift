//
//  VcrListView.swift
//  demoshift
//
//  Created by Александр Иванов on 21.11.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct VcrListView: View {
    @ObservedObject private var state: VcrListState
    @State var showAddVcrView = false

    private let interactor: VcrListInteractor

    init() {
        let state = VcrListState()
        self.state = state
        self.interactor = VcrListInteractor(state: state)
    }

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
                    ForEach(state.vcrs) {
                        if #available(iOS 15.0, *) {
                            VCRCard(name: $0.name, isActive: $0.isActive)
                                .listRowSeparator(.hidden)
                        } else {
                            VCRCard(name: $0.name, isActive: $0.isActive)
                        }
                    }
                    .listRowBackground(Color.clear)
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
        .onAppear {
            interactor.loadAllVcrs()
        }
    }

    func getAppName() -> String {
        guard let dictionary = Bundle.main.infoDictionary,
              let name = dictionary["CFBundleName"] as? String else {
                  return "Client Application"
              }
        return name
    }

}
