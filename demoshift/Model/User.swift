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

    @NSManaged private(set) var certID: Data
    @NSManaged private(set) var certBody: Data

    static func makeUser(forCert cert: Cert, withTokenSerial tokenSerial: String, context: NSManagedObjectContext?) -> User? {
        guard let ctx = context else {
            return nil
        }
        return User(cert, withTokenSerial: tokenSerial, context: ctx)
    }

    convenience init?(_ cert: Cert, withTokenSerial tokenSerial: String, context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "User", in: context) else {
            return nil
        }
        self.init(entity: entity, insertInto: context)
        self.name = cert.commonName
        self.position = cert.position
        self.company = cert.companyName
        self.expired = cert.expired
        self.tokenSerial = tokenSerial
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
