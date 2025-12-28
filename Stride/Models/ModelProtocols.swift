import Foundation
import SwiftData

protocol IdentifiedModel: PersistentModel, Identifiable where ID == UUID {
    var id: UUID { get set }
}
