import Foundation

struct FileMetadata: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let folderId: String
    let path: String
    let size: Int64
    let mimeType: String
    let checksum: String?
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String
    let updatedBy: String
    let permissions: [String]
    let isShared: Bool
    let shareSettings: ShareSettings?
    let metadata: [String: String]
    let version: Int
    let isLatest: Bool
    
    // Computed properties
    var canDownload: Bool {
        return permissions.contains("download_document")
    }
    
    var canUpload: Bool {
        return permissions.contains("create_document")
    }
    
    var canDelete: Bool {
        return permissions.contains("delete_document")
    }
    
    var canEdit: Bool {
        return permissions.contains("edit_document_content")
    }
    
    var displayPath: String {
        return path.isEmpty ? name : "\(path)/\(name)"
    }
    
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
    
    var fileExtension: String {
        return (name as NSString).pathExtension.lowercased()
    }
    
    var isImage: Bool {
        return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"].contains(fileExtension)
    }
    
    var isDocument: Bool {
        return ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf"].contains(fileExtension)
    }
    
    var isVideo: Bool {
        return ["mp4", "avi", "mov", "wmv", "flv", "webm", "mkv"].contains(fileExtension)
    }
    
    var isAudio: Bool {
        return ["mp3", "wav", "aac", "flac", "ogg", "m4a"].contains(fileExtension)
    }
    
    var systemIcon: String {
        if isImage { return "photo" }
        if isDocument { return "doc.text" }
        if isVideo { return "video" }
        if isAudio { return "music.note" }
        if fileExtension == "pdf" { return "doc.richtext" }
        if fileExtension == "zip" || fileExtension == "rar" { return "archivebox" }
        return "doc"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, path, size, version, metadata, permissions, checksum
        case folderId = "folder_id"
        case mimeType = "mime_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case updatedBy = "updated_by"
        case isShared = "is_shared"
        case shareSettings = "share_settings"
        case isLatest = "is_latest"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        folderId = try container.decode(String.self, forKey: .folderId)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int64.self, forKey: .size)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        checksum = try container.decodeIfPresent(String.self, forKey: .checksum)
        permissions = try container.decode([String].self, forKey: .permissions)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        isLatest = try container.decodeIfPresent(Bool.self, forKey: .isLatest) ?? true
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
        try container.encode(folderId, forKey: .folderId)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(checksum, forKey: .checksum)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(version, forKey: .version)
        try container.encode(isLatest, forKey: .isLatest)
        try container.encode(isShared, forKey: .isShared)
        try container.encodeIfPresent(shareSettings, forKey: .shareSettings)
        
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(updatedBy, forKey: .updatedBy)
    }
}
