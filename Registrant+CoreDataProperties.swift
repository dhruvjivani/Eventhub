//
//  Registrant+CoreDataProperties.swift
//  Eventhub
//
//  Created by Dhruv Rasikbhai Jivani on 10/2/25.
//
//

public import Foundation
public import CoreData


public typealias RegistrantCoreDataPropertiesSet = NSSet

extension Registrant {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Registrant> {
        return NSFetchRequest<Registrant>(entityName: "Registrant")
    }

    @NSManaged public var age: Int16
    @NSManaged public var email: String?
    @NSManaged public var fullname: String?
    @NSManaged public var gender: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isStudent: Bool
    @NSManaged public var timestamp: Date?

}

extension Registrant : Identifiable {

}
