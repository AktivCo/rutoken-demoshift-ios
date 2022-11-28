//
//  User.swift
//  demoshift
//
//  Created by Vova Badyaev on 10.06.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import CoreData
import Foundation


class User: NSManagedObject, Identifiable {
    @NSManaged private(set) var name: String
    @NSManaged private(set) var position: String
    @NSManaged private(set) var company: String
    @NSManaged private(set) var expired: String

    @NSManaged private(set) var tokenSerial: String
    @NSManaged private var tokenInterfaces: Data

    var tokenSupportedInterfaces: [TokenInterface] {
        (try? JSONDecoder().decode([TokenInterface].self, from: tokenInterfaces)) ?? [TokenInterface]()
    }

    @NSManaged private(set) var certID: Data
    @NSManaged private(set) var certBody: Data

    static func makeUser(forCert cert: Cert, withTokenSerial tokenSerial: String, tokenInterfaces: [TokenInterface],
                         context: NSManagedObjectContext?) -> User? {
        guard let ctx = context else {
            return nil
        }
        guard let interfaces = try? JSONEncoder().encode(tokenInterfaces) else {
            return nil
        }
        return User(cert, withTokenSerial: tokenSerial, tokenInterfaces: interfaces, context: ctx)
    }

    convenience init?(_ cert: Cert, withTokenSerial tokenSerial: String, tokenInterfaces: Data,
                      context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "User", in: context) else {
            return nil
        }
        self.init(entity: entity, insertInto: context)
        self.name = cert.commonName
        self.position = cert.position
        self.company = cert.companyName
        self.expired = cert.expired
        self.tokenSerial = tokenSerial
        self.tokenInterfaces = tokenInterfaces
        self.certID = cert.id
        self.certBody = cert.body
    }
}

extension User {
    static func getAllUsers() -> NSFetchRequest<User> {
        let request: NSFetchRequest<User> = NSFetchRequest<User>(entityName: "User")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        return request
    }
}
