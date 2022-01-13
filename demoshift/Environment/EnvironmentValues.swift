//
//  EnvironmentValues.swift
//  demoshift
//
//  Created by Александр Иванов on 22.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import SwiftUI


struct InteractorsContainer {
    let addVcrInteractor: AddVcrInteractor?
    let vcrListInteractor: VcrListInteractor?
    let userListInteractor: UserListInteractor?
    let tokenListInteractor: TokenListInteractor?
    let signInteractor: SignInteractor?
}

private struct InteractorsContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue = InteractorsContainer(addVcrInteractor: nil,
                                                   vcrListInteractor: nil,
                                                   userListInteractor: nil,
                                                   tokenListInteractor: nil,
                                                   signInteractor: nil)
}

extension EnvironmentValues {
    var interactorsContainer: InteractorsContainer {
        get { self[InteractorsContainerEnvironmentKey.self] }
        set { self[InteractorsContainerEnvironmentKey.self] = newValue }
    }
}
