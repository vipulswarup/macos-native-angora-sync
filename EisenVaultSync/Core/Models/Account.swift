import Foundation
import CoreData

@objc(SyncAccount)
public class SyncAccount: NSManagedObject {
    
}

extension SyncAccount {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SyncAccount> {
        return NSFetchRequest<SyncAccount>(entityName: "SyncAccount")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var serverURL: String
    @NSManaged public var email: String
    @NSManaged public var lastSync: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
}

extension SyncAccount: Identifiable {
    
}
