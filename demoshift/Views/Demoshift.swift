//
//  Demoshift.swift
//  demoshift
//
//  Created by Vova Badyaev on on 16.02.2023.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import CoreData
import SwiftUI


@main
struct DemoshiftApp: App {
    let context: NSManagedObjectContext

    let pcscWrapper: PcscWrapper
    let vcrWrapper: VcrWrapper

    let vcrListState: VcrListState
    let addVcrState: AddVcrState
    let routingState: RoutingState
    let tokenListState: TokenListState
    let signState: SignState

    let interactorsContainer: InteractorsContainer

    init() {
        let container = NSPersistentContainer(name: "CoreDataUser")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.context = container.viewContext

        self.pcscWrapper = PcscWrapper()
        self.vcrWrapper = VcrWrapper(pcscWrapper: pcscWrapper)

        self.vcrListState = VcrListState()
        self.addVcrState = AddVcrState()
        self.routingState = RoutingState()
        self.tokenListState = TokenListState()
        self.signState = SignState()
        self.interactorsContainer = InteractorsContainer(addVcrInteractor: AddVcrInteractor(routingState: routingState,
                                                                                            state: addVcrState,
                                                                                            vcrWrapper: vcrWrapper),
                                                         vcrListInteractor: VcrListInteractor(state: vcrListState,
                                                                                              vcrWrapper: vcrWrapper),
                                                         userListInteractor: UserListInteractor(pcscWrapper),
                                                         tokenListInteractor: TokenListInteractor(state: tokenListState,
                                                                                                  pcscWrapper),
                                                         signInteractor: SignInteractor(state: signState,
                                                                                        routingState: routingState,
                                                                                        pcscWrapper))
    }

    var body: some Scene {
        WindowGroup {
            UserListView()
                .environment(\.managedObjectContext, context)
                .environmentObject(vcrListState)
                .environmentObject(addVcrState)
                .environmentObject(routingState)
                .environmentObject(tokenListState)
                .environmentObject(signState)
                .environment(\.interactorsContainer, interactorsContainer)
        }
    }
}
