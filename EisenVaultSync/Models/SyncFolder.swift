import Foundation
import CoreData

// MARK: - Sync Status Enum

enum SyncStatus: String, CaseIterable, Codable {
    case paused = "paused"
    case active = "active"
    case syncing = "syncing"
    case error = "error"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .paused: return "Paused"
        case .active: return "Active"
        case .syncing: return "Syncing"
        case .error: return "Error"
        case .completed: return "Completed"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .paused: return "pause.circle"
        case .active: return "checkmark.circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .paused: return "orange"
        case .active: return "green"
        case .syncing: return "blue"
        case .error: return "red"
        case .completed: return "green"
        }
    }
}

// MARK: - Sync Folder Model

struct SyncFolder: Codable, Identifiable {
    let id: String
    let remoteFolderId: String
    let remoteFolderName: String
    let remoteFolderPath: String
    let localPath: String
    let accountId: String
    let status: SyncStatus
    let lastSyncDate: Date?
    let lastError: String?
    let isEnabled: Bool
    let syncDirection: SyncDirection
    let conflictResolution: ConflictResolution
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var displayName: String {
        return remoteFolderName
    }
    
    var displayPath: String {
        return remoteFolderPath.isEmpty ? remoteFolderName : "\(remoteFolderPath)/\(remoteFolderName)"
    }
    
    var localURL: URL {
        return URL(fileURLWithPath: localPath)
    }
    
    var statusIcon: String {
        return status.systemIcon
    }
    
    var statusColor: String {
        return status.color
    }
    
    var lastSyncText: String {
        guard let lastSyncDate = lastSyncDate else {
            return "Never synced"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
    
    // MARK: - Initializer
    
    init(
        id: String,
        remoteFolderId: String,
        remoteFolderName: String,
        remoteFolderPath: String,
        localPath: String,
        accountId: String,
        status: SyncStatus,
        lastSyncDate: Date?,
        lastError: String?,
        isEnabled: Bool,
        syncDirection: SyncDirection,
        conflictResolution: ConflictResolution,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.remoteFolderId = remoteFolderId
        self.remoteFolderName = remoteFolderName
        self.remoteFolderPath = remoteFolderPath
        self.localPath = localPath
        self.accountId = accountId
        self.status = status
        self.lastSyncDate = lastSyncDate
        self.lastError = lastError
        self.isEnabled = isEnabled
        self.syncDirection = syncDirection
        self.conflictResolution = conflictResolution
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, isEnabled, syncDirection, conflictResolution
        case remoteFolderId = "remote_folder_id"
        case remoteFolderName = "remote_folder_name"
        case remoteFolderPath = "remote_folder_path"
        case localPath = "local_path"
        case accountId = "account_id"
        case lastSyncDate = "last_sync_date"
        case lastError = "last_error"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        remoteFolderId = try container.decode(String.self, forKey: .remoteFolderId)
        remoteFolderName = try container.decode(String.self, forKey: .remoteFolderName)
        remoteFolderPath = try container.decode(String.self, forKey: .remoteFolderPath)
        localPath = try container.decode(String.self, forKey: .localPath)
        accountId = try container.decode(String.self, forKey: .accountId)
        status = try container.decode(SyncStatus.self, forKey: .status)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        syncDirection = try container.decode(SyncDirection.self, forKey: .syncDirection)
        conflictResolution = try container.decode(ConflictResolution.self, forKey: .conflictResolution)
        lastError = try container.decodeIfPresent(String.self, forKey: .lastError)
        
        // Parse dates
        if let lastSyncString = try container.decodeIfPresent(String.self, forKey: .lastSyncDate) {
            let dateFormatter = ISO8601DateFormatter()
            lastSyncDate = dateFormatter.date(from: lastSyncString)
        } else {
            lastSyncDate = nil
        }
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        let dateFormatter = ISO8601DateFormatter()
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(remoteFolderId, forKey: .remoteFolderId)
        try container.encode(remoteFolderName, forKey: .remoteFolderName)
        try container.encode(remoteFolderPath, forKey: .remoteFolderPath)
        try container.encode(localPath, forKey: .localPath)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(status, forKey: .status)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(syncDirection, forKey: .syncDirection)
        try container.encode(conflictResolution, forKey: .conflictResolution)
        try container.encodeIfPresent(lastError, forKey: .lastError)
        
        let dateFormatter = ISO8601DateFormatter()
        if let lastSyncDate = lastSyncDate {
            try container.encode(dateFormatter.string(from: lastSyncDate), forKey: .lastSyncDate)
        }
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

// MARK: - Sync Direction Enum

enum SyncDirection: String, CaseIterable, Codable {
    case bidirectional = "bidirectional"
    case downloadOnly = "download_only"
    case uploadOnly = "upload_only"
    
    var displayName: String {
        switch self {
        case .bidirectional: return "Two-way Sync"
        case .downloadOnly: return "Download Only"
        case .uploadOnly: return "Upload Only"
        }
    }
    
    var description: String {
        switch self {
        case .bidirectional: return "Sync changes in both directions"
        case .downloadOnly: return "Only download changes from server"
        case .uploadOnly: return "Only upload changes to server"
        }
    }
}

// MARK: - Conflict Resolution Enum

enum ConflictResolution: String, CaseIterable, Codable {
    case remoteWins = "remote_wins"
    case localWins = "local_wins"
    case askUser = "ask_user"
    case createCopy = "create_copy"
    
    var displayName: String {
        switch self {
        case .remoteWins: return "Server Wins"
        case .localWins: return "Local Wins"
        case .askUser: return "Ask User"
        case .createCopy: return "Create Copy"
        }
    }
    
    var description: String {
        switch self {
        case .remoteWins: return "Server version takes precedence"
        case .localWins: return "Local version takes precedence"
        case .askUser: return "Prompt user to choose"
        case .createCopy: return "Keep both versions"
        }
    }
}

// MARK: - Sync Folder Extensions

extension SyncFolder {
    static func create(
        remoteFolder: FolderMetadata,
        accountId: String,
        localPath: String
    ) -> SyncFolder {
        return SyncFolder(
            id: UUID().uuidString,
            remoteFolderId: remoteFolder.id,
            remoteFolderName: remoteFolder.name,
            remoteFolderPath: remoteFolder.path,
            localPath: localPath,
            accountId: accountId,
            status: SyncStatus.paused,
            lastSyncDate: nil,
            lastError: nil,
            isEnabled: true,
            syncDirection: SyncDirection.bidirectional,
            conflictResolution: ConflictResolution.remoteWins,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func withStatus(_ newStatus: SyncStatus) -> SyncFolder {
        return SyncFolder(
            id: id,
            remoteFolderId: remoteFolderId,
            remoteFolderName: remoteFolderName,
            remoteFolderPath: remoteFolderPath,
            localPath: localPath,
            accountId: accountId,
            status: newStatus,
            lastSyncDate: lastSyncDate,
            lastError: lastError,
            isEnabled: isEnabled,
            syncDirection: syncDirection,
            conflictResolution: conflictResolution,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    func withLastSync(_ date: Date) -> SyncFolder {
        return SyncFolder(
            id: id,
            remoteFolderId: remoteFolderId,
            remoteFolderName: remoteFolderName,
            remoteFolderPath: remoteFolderPath,
            localPath: localPath,
            accountId: accountId,
            status: status,
            lastSyncDate: date,
            lastError: lastError,
            isEnabled: isEnabled,
            syncDirection: syncDirection,
            conflictResolution: conflictResolution,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    func withError(_ error: String) -> SyncFolder {
        return SyncFolder(
            id: id,
            remoteFolderId: remoteFolderId,
            remoteFolderName: remoteFolderName,
            remoteFolderPath: remoteFolderPath,
            localPath: localPath,
            accountId: accountId,
            status: SyncStatus.error,
            lastSyncDate: lastSyncDate,
            lastError: error,
            isEnabled: isEnabled,
            syncDirection: syncDirection,
            conflictResolution: conflictResolution,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
