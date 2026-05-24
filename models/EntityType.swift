/// EntityType defines what kind of information was detected in the scanned image.
///
/// Designed to be open for extension — the `.custom` case allows any consumer
/// to define their own entity types without modifying this file.
/// This follows the Open/Closed Principle from SOLID.
public enum EntityType: Equatable {

    // MARK: - Contact
    case phone
    case email

    // MARK: - Web
    case url
    case socialHandle

    // MARK: - Time
    case date
    case time

    // MARK: - Commerce
    case price
    case discount

    // MARK: - Location
    case address

    // MARK: - Extension point
    /// Allows any consumer to define custom entity types.
    /// Example: .custom("eventName") or .custom("dressCode")
    case custom(String)
}
