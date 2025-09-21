import Foundation

struct FolderMetadata: Codable, Identifiable, Hashable {
    let id: String
    let rawFileName: String
    let description: String?
    let parentPath: String?
    let materializePath: String
    let originalCloudRelativePath: String?
    let convertedCloudRelativePath: String?
    let documentCategory: String?
    let dataEntry: [DataEntry]?
    let size: Int64
    let portal: String
    let fileCount: Int
    let collaborators: [Collaborator]?
    let isBeingTrashed: Bool
    let isBeingMoved: Bool
    let isBeingCopied: Bool
    let isDepartment: Bool
    let isFolder: Bool
    let isFile: Bool
    let isLocked: Bool?
    let createdBy: String
    let editedBy: String
    let ocrLanguages: [String]
    let isConvertable: Bool
    let isConverted: Bool
    let errorList: [String]
    let relatedFiles: [String]
    let createdAt: Date
    let updatedAt: Date
    let version: String?
    let `extension`: String?
    let watermarkedLink: String?
    let upload: String?
    
    // Computed properties
    var name: String {
        return rawFileName
    }
    
    var parentId: String? {
        // Extract parent ID from parentPath if available
        return nil // We'll need to implement this based on the actual structure
    }
    
    var path: String {
        return materializePath
    }
    
    var permissions: [String] {
        // Default permissions for now - we'll need to get these from the API
        return ["list_folder_content", "download_document"]
    }
    
    var isShared: Bool {
        return (collaborators?.count ?? 0) > 1
    }
    
    var shareSettings: ShareSettings? {
        return nil // We'll implement this if needed
    }
    
    var metadata: [String: String] {
        var result: [String: String] = [:]
        if let description = description {
            result["description"] = description
        }
        if let ext = `extension` {
            result["extension"] = ext
        }
        return result
    }
    
    var folderCount: Int {
        return isFolder ? 1 : 0 // This is a simplified approach
    }
    
    var totalSize: Int64 {
        return size
    }
    
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
        rawFileName: String,
        description: String?,
        parentPath: String?,
        materializePath: String,
        originalCloudRelativePath: String?,
        convertedCloudRelativePath: String?,
        documentCategory: String?,
        dataEntry: [DataEntry]?,
        size: Int64,
        portal: String,
        fileCount: Int,
        collaborators: [Collaborator]?,
        isBeingTrashed: Bool,
        isBeingMoved: Bool,
        isBeingCopied: Bool,
        isDepartment: Bool,
        isFolder: Bool,
        isFile: Bool,
        isLocked: Bool?,
        createdBy: String,
        editedBy: String,
        ocrLanguages: [String],
        isConvertable: Bool,
        isConverted: Bool,
        errorList: [String],
        relatedFiles: [String],
        createdAt: Date,
        updatedAt: Date,
        version: String?,
        `extension`: String?,
        watermarkedLink: String?,
        upload: String?
    ) {
        self.id = id
        self.rawFileName = rawFileName
        self.description = description
        self.parentPath = parentPath
        self.materializePath = materializePath
        self.originalCloudRelativePath = originalCloudRelativePath
        self.convertedCloudRelativePath = convertedCloudRelativePath
        self.documentCategory = documentCategory
        self.dataEntry = dataEntry
        self.size = size
        self.portal = portal
        self.fileCount = fileCount
        self.collaborators = collaborators
        self.isBeingTrashed = isBeingTrashed
        self.isBeingMoved = isBeingMoved
        self.isBeingCopied = isBeingCopied
        self.isDepartment = isDepartment
        self.isFolder = isFolder
        self.isFile = isFile
        self.isLocked = isLocked
        self.createdBy = createdBy
        self.editedBy = editedBy
        self.ocrLanguages = ocrLanguages
        self.isConvertable = isConvertable
        self.isConverted = isConverted
        self.errorList = errorList
        self.relatedFiles = relatedFiles
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.extension = `extension`
        self.watermarkedLink = watermarkedLink
        self.upload = upload
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case rawFileName = "raw_file_name"
        case description
        case parentPath = "parent_path"
        case materializePath = "materialize_path"
        case originalCloudRelativePath = "original_cloud_relative_path"
        case convertedCloudRelativePath = "converted_cloud_relative_path"
        case documentCategory = "document_category"
        case dataEntry = "data_entry"
        case size
        case portal
        case fileCount = "file_count"
        case collaborators
        case isBeingTrashed = "is_being_trashed"
        case isBeingMoved = "is_being_moved"
        case isBeingCopied = "is_being_copied"
        case isDepartment = "is_department"
        case isFolder = "is_folder"
        case isFile = "is_file"
        case isLocked = "is_locked"
        case createdBy = "created_by"
        case editedBy = "edited_by"
        case ocrLanguages = "ocr_languages"
        case isConvertable = "is_convertable"
        case isConverted = "is_converted"
        case errorList = "error_list"
        case relatedFiles = "related_files"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case version
        case `extension`
        case watermarkedLink = "watermarked_link"
        case upload
    }
}

// MARK: - Supporting Models

struct DataEntry: Codable, Hashable {
    let metadata: String
    let name: String
    let value: String?
    let id: String
}

struct Collaborator: Codable, Hashable {
    let buffer: String
}

struct ShareSettings: Codable, Hashable, Equatable {
    let isPublic: Bool
    let allowDownload: Bool
    let allowEdit: Bool
    let expirationDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case isPublic = "is_public"
        case allowDownload = "allow_download"
        case allowEdit = "allow_edit"
        case expirationDate = "expiration_date"
    }
}