//
//  UserView.swift
//  demoshift
//
//  Created by Pavel Kamenov on 13.05.2020.
//  Copyright © 2020 Aktiv Co. All rights reserved.
//

import SwiftUI
import CoreData

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

struct UserView: View {
    let name: String
    let position: String
    let company: String
    let expired: String

    init(user: User) {
        self.name = user.name
        self.position = user.position
        self.company = user.company
        self.expired = user.expired
    }

    func field(caption: String, text: String) -> some View {
        VStack(alignment: .leading) {
            Text(caption)
                .font(.caption)
                .foregroundColor(Color("blue-text"))
                .padding(.bottom, 4)
            Text(text)
                .font(.subheadline)
        }
        .padding(.top, 16)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .fontWeight(.semibold)
                .font(.headline)

            field(caption: "Должность", text: position)
            field(caption: "Организация", text: company)
            field(caption: "Сертификат истекает", text: expired)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
        .padding(.horizontal, 24)
        .background(Color("listitem-background"))
        .cornerRadius(15)
        .shadow(color: Color(.systemGray), radius: 5, x: 0, y: 0)
    }
}
