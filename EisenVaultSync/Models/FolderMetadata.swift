import Foundation

struct FolderMetadata: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let parentId: String?
    let path: String
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String
    let updatedBy: String
    let permissions: [String]
    let isShared: Bool
    let shareSettings: ShareSettings?
    let metadata: [String: String]
    let fileCount: Int
    let folderCount: Int
    let totalSize: Int64
    
    // Computed properties
    var canSync: Bool {
        return permissions.contains("list_folder_content") && 
               permissions.contains("download_document")
    }
    
    var canUpload: Bool {
        return permissions.contains("create_document")
    }
    
    var canDelete: Bool {
        return permissions.contains("delete_folder")
    }
    
    var canEdit: Bool {
        return permissions.contains("edit_folder_metadata")
    }
    
    var displayPath: String {
        return path.isEmpty ? name : "\(path)/\(name)"
    }
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
    
    // MARK: - Initializer
    
    init(
        id: String,
        name: String,
        parentId: String?,
        path: String,
        createdAt: Date,
        updatedAt: Date,
        createdBy: String,
        updatedBy: String,
        permissions: [String],
        isShared: Bool,
        shareSettings: ShareSettings?,
        metadata: [String: String],
        fileCount: Int,
        folderCount: Int,
        totalSize: Int64
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.path = path
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.updatedBy = updatedBy
        self.permissions = permissions
        self.isShared = isShared
        self.shareSettings = shareSettings
        self.metadata = metadata
        self.fileCount = fileCount
        self.folderCount = folderCount
        self.totalSize = totalSize
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, path, permissions, metadata, fileCount, folderCount, totalSize
        case parentId = "parent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case updatedBy = "updated_by"
        case isShared = "is_shared"
        case shareSettings = "share_settings"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        path = try container.decode(String.self, forKey: .path)
        permissions = try container.decode([String].self, forKey: .permissions)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        fileCount = try container.decodeIfPresent(Int.self, forKey: .fileCount) ?? 0
        folderCount = try container.decodeIfPresent(Int.self, forKey: .folderCount) ?? 0
        totalSize = try container.decodeIfPresent(Int64.self, forKey: .totalSize) ?? 0
        isShared = try container.decodeIfPresent(Bool.self, forKey: .isShared) ?? false
        shareSettings = try container.decodeIfPresent(ShareSettings.self, forKey: .shareSettings)
        
        // Parse dates
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        let dateFormatter = ISO8601DateFormatter()
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        createdBy = try container.decode(String.self, forKey: .createdBy)
        updatedBy = try container.decode(String.self, forKey: .updatedBy)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(path, forKey: .path)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(fileCount, forKey: .fileCount)
        try container.encode(folderCount, forKey: .folderCount)
        try container.encode(totalSize, forKey: .totalSize)
        try container.encode(isShared, forKey: .isShared)
        try container.encodeIfPresent(shareSettings, forKey: .shareSettings)
        
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(updatedBy, forKey: .updatedBy)
    }
}

struct ShareSettings: Codable, Hashable, Equatable {
    let isPublic: Bool
    let allowDownload: Bool
    let allowUpload: Bool
    let expirationDate: Date?
    let password: String?
    let allowedUsers: [String]
    let allowedGroups: [String]
    
    enum CodingKeys: String, CodingKey {
        case isPublic = "is_public"
        case allowDownload = "allow_download"
        case allowUpload = "allow_upload"
        case expirationDate = "expiration_date"
        case password
        case allowedUsers = "allowed_users"
        case allowedGroups = "allowed_groups"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        allowDownload = try container.decode(Bool.self, forKey: .allowDownload)
        allowUpload = try container.decode(Bool.self, forKey: .allowUpload)
        password = try container.decodeIfPresent(String.self, forKey: .password)
        allowedUsers = try container.decodeIfPresent([String].self, forKey: .allowedUsers) ?? []
        allowedGroups = try container.decodeIfPresent([String].self, forKey: .allowedGroups) ?? []
        
        if let expirationString = try container.decodeIfPresent(String.self, forKey: .expirationDate) {
            let dateFormatter = ISO8601DateFormatter()
            expirationDate = dateFormatter.date(from: expirationString)
        } else {
            expirationDate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(allowDownload, forKey: .allowDownload)
        try container.encode(allowUpload, forKey: .allowUpload)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encode(allowedUsers, forKey: .allowedUsers)
        try container.encode(allowedGroups, forKey: .allowedGroups)
        
        if let expirationDate = expirationDate {
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: expirationDate), forKey: .expirationDate)
        }
    }
}
