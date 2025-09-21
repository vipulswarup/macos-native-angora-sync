import Foundation
import Combine

class FolderService: ObservableObject {
    private let networkManager = NetworkManager.shared
    private let accountManager = AccountManager.shared
    
    // MARK: - Folder Operations
    
    func fetchFolders(parentId: String? = nil) async throws -> [FolderMetadata] {
        guard let activeAccount = accountManager.activeAccount else {
            throw FolderError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FolderError.noAuthToken
        }
        
        let url: URL
        if let parentId = parentId {
            // Fetch children of a specific folder
            guard let folderURL = URL(string: "\(activeAccount.serverURL ?? "")/api/folders/\(parentId)/children") else {
                throw FolderError.invalidURL
            }
            url = folderURL
        } else {
            // Fetch root-level folders (departments)
            guard let rootURL = URL(string: "\(activeAccount.serverURL ?? "")/api/folders") else {
                throw FolderError.invalidURL
            }
            url = rootURL
        }
        
        print("📁 Fetching folders from: \(url.absoluteString)")
        
        let response: FolderListResponse = try await networkManager.makeRequest(
            url: url,
            method: .GET,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ],
            responseType: FolderListResponse.self
        )
        
        // Filter out null values from the response
        let validFolders = response.data.compactMap { $0 }
        print("📁 Fetched \(validFolders.count) folders (filtered from \(response.data.count) total)")
        return validFolders
    }
    
    func fetchFolderDetails(folderId: String) async throws -> FolderMetadata {
        guard let activeAccount = accountManager.activeAccount else {
            throw FolderError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FolderError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/folders/\(folderId)") else {
            throw FolderError.invalidURL
        }
        
        print("📁 Fetching folder details for: \(folderId)")
        
        let response: FolderDetailResponse = try await networkManager.makeRequest(
            url: url,
            method: .GET,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ],
            responseType: FolderDetailResponse.self
        )
        
        return response.data
    }
    
    func createFolder(name: String, parentId: String? = nil) async throws -> FolderMetadata {
        guard let activeAccount = accountManager.activeAccount else {
            throw FolderError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FolderError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/folders") else {
            throw FolderError.invalidURL
        }
        
        let request = CreateFolderRequest(name: name, parentId: parentId)
        let requestData = try JSONEncoder().encode(request)
        
        print("📁 Creating folder: \(name) in parent: \(parentId ?? "root")")
        
        let response: FolderDetailResponse = try await networkManager.makeRequest(
            url: url,
            method: .POST,
            body: requestData,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ],
            responseType: FolderDetailResponse.self
        )
        
        print("📁 Created folder: \(response.data.name)")
        return response.data
    }
    
    // MARK: - Sync Operations
    
    func fetchRootFolders() async throws -> [FolderMetadata] {
        // Fetch departments from the departments endpoint
        guard let activeAccount = accountManager.activeAccount else {
            throw FolderError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FolderError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/departments?slim=true") else {
            throw FolderError.invalidURL
        }
        
        print("📁 Fetching departments from: \(url.absoluteString)")
        
        let response: DepartmentListResponse = try await networkManager.makeRequest(
            url: url,
            method: .GET,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ],
            responseType: DepartmentListResponse.self
        )
        
        // Convert departments to FolderMetadata format
        let departments = response.data.compactMap { department -> FolderMetadata? in
            guard let department = department else { return nil }
            return createFolderMetadataFromDepartment(department)
        }
        
        print("📁 Fetched \(departments.count) departments")
        return departments
    }
    
    func fetchFolderChildren(folderId: String) async throws -> [FolderMetadata] {
        // Fetch children of a specific folder
        return try await fetchFolders(parentId: folderId)
    }
    
    func getSyncableFolders() async throws -> [FolderMetadata] {
        // Fetch all folders and filter for syncable ones
        let allFolders = try await fetchFolders()
        return allFolders.filter { $0.canSync }
    }
    
    func validateFolderForSync(folderId: String) async throws -> Bool {
        let folder = try await fetchFolderDetails(folderId: folderId)
        return folder.canSync && folder.permissions.contains("list_folder_content")
    }
}

// MARK: - Request/Response Models

struct CreateFolderRequest: Codable {
    let name: String
    let parentId: String?
}

struct FolderListResponse: Codable {
    let status: Int
    let meta: PaginationMeta?
    let data: [FolderMetadata?]
    let notifications: [String]
    let errors: [String]
}

struct PaginationMeta: Codable {
    let currentPage: Int
    let itemsPerPage: Int
    let totalPages: Int
    let totalRecords: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case itemsPerPage = "items_per_page"
        case totalPages = "total_pages"
        case totalRecords = "total_records"
        case hasMore = "has_more"
    }
}

struct DepartmentListResponse: Codable {
    let status: Int
    let meta: PaginationMeta?
    let data: [Department?]
    let notifications: [String]
    let errors: [String]
}

struct Department: Codable {
    let id: String
    let rawFileName: String
    let description: String?
    let parentPath: String?
    let materializePath: String
    let isDepartment: Bool
    let createdBy: String
    let editedBy: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case rawFileName = "raw_file_name"
        case description
        case parentPath = "parent_path"
        case materializePath = "materialize_path"
        case isDepartment = "is_department"
        case createdBy = "created_by"
        case editedBy = "edited_by"
    }
}

struct FolderDetailResponse: Codable {
    let status: Int
    let data: FolderMetadata
    let notifications: [String]
    let errors: [String]
}

// MARK: - Helper Functions

extension FolderService {
    private func createFolderMetadataFromDepartment(_ department: Department) -> FolderMetadata {
        // Create a FolderMetadata from Department data
        // We need to provide all required fields for the new FolderMetadata structure
        return FolderMetadata(
            id: department.id,
            rawFileName: department.rawFileName,
            description: department.description,
            parentPath: department.parentPath,
            materializePath: department.materializePath,
            originalCloudRelativePath: nil,
            convertedCloudRelativePath: nil,
            documentCategory: nil,
            dataEntry: nil,
            size: 0,
            portal: "web",
            fileCount: 0,
            collaborators: nil,
            isBeingTrashed: false,
            isBeingMoved: false,
            isBeingCopied: false,
            isDepartment: department.isDepartment,
            isFolder: true, // Departments are treated as folders
            isFile: false,
            isLocked: false,
            createdBy: department.createdBy,
            editedBy: department.editedBy,
            ocrLanguages: [],
            isConvertable: false,
            isConverted: false,
            errorList: [],
            relatedFiles: [],
            createdAt: Date(), // Use current date as fallback
            updatedAt: Date(), // Use current date as fallback
            version: nil,
            extension: nil,
            watermarkedLink: nil,
            upload: nil
        )
    }
}

// MARK: - Error Types

enum FolderError: Error, LocalizedError {
    case noActiveAccount
    case noAuthToken
    case invalidURL
    case networkError(String)
    case serverError(String)
    case folderNotFound
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noActiveAccount:
            return "No active account found"
        case .noAuthToken:
            return "Authentication token not found"
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .folderNotFound:
            return "Folder not found"
        case .permissionDenied:
            return "Permission denied to access folder"
        }
    }
}
