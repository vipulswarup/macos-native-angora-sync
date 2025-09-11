import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let status: Int
    let data: LoginData
    let notifications: [String]
    let errors: [String]
}

struct LoginData: Codable {
    let user: User
}

struct User: Codable {
    let id: String
    let settings: UserSettings
    let firstname: String
    let lastname: String
    let customerHostname: String
    let email: String
    let jobTitle: String
    let isRoot: Bool
    let forcePasswordChange: Bool
    let isTwoFactorEnabled: Bool
    let twoFactorProfileLocked: Bool
    let avatar: String
    let signature: String
    let landline: String?
    let mobile: String?
    let timezone: String
    let locale: String
    let permissions: [String: String]
    let nextStep: String
    let storageUsed: Double
    let storageLimit: Double
    
    enum CodingKeys: String, CodingKey {
        case id, settings, firstname, lastname, email, avatar, signature, landline, mobile, timezone, locale, permissions
        case customerHostname = "customer_hostname"
        case jobTitle = "job_title"
        case isRoot = "is_root"
        case forcePasswordChange = "force_password_change"
        case isTwoFactorEnabled = "is_two_factor_enabled"
        case twoFactorProfileLocked = "two_factor_profile_locked"
        case nextStep = "next_step"
        case storageUsed = "storage_used"
        case storageLimit = "storage_limit"
    }
}

struct UserSettings: Codable {
    let receiveAppNotifications: Bool
    let receiveTaskNotifications: Bool
    let receiveCommentNotifications: Bool
    let receiveDocumentNotifications: Bool
    let isTourEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case receiveAppNotifications = "receive_app_notifications"
        case receiveTaskNotifications = "receive_task_notifications"
        case receiveCommentNotifications = "receive_comment_notifications"
        case receiveDocumentNotifications = "receive_document_notifications"
        case isTourEnabled = "is_tour_enabled"
    }
}

struct AuthErrorResponse: Codable {
    let message: String
    let code: String?
}

struct TokenVerificationResponse: Codable {
    let status: Int
    let data: TokenVerificationData
    let notifications: [String]
    let errors: [String]
}

struct TokenVerificationData: Codable {
    let id: String
    let customerHostname: String
    let firstname: String
    let lastname: String
    let email: String
    let jobTitle: String
    let isRoot: Bool
    let avatar: String
    let signature: String
    let mobileDialCode: String?
    let isTwoFactorEnabled: Bool
    let twoFactorProfileLocked: Bool
    let mobile: String?
    let landline: String?
    let permissions: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, firstname, lastname, email, avatar, signature, mobile, landline, permissions
        case customerHostname = "customer_hostname"
        case jobTitle = "job_title"
        case isRoot = "is_root"
        case mobileDialCode = "mobile_dial_code"
        case isTwoFactorEnabled = "is_two_factor_enabled"
        case twoFactorProfileLocked = "two_factor_profile_locked"
    }
}

enum AuthState: Equatable {
    case idle
    case loading
    case authenticated
    case error(String)
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError(String)
    case serverError(String)
    case tokenExpired
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .tokenExpired:
            return "Session expired. Please log in again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
