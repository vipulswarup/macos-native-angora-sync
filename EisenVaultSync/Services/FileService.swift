import Foundation
import Combine

class FileService: ObservableObject {
    private let networkManager = NetworkManager.shared
    private let accountManager = AccountManager.shared
    
    // MARK: - File Operations
    
    func fetchFiles(folderId: String) async throws -> [FileMetadata] {
        guard let activeAccount = accountManager.activeAccount else {
            throw FileError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FileError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/folders/\(folderId)/files") else {
            throw FileError.invalidURL
        }
        
        print("📄 Fetching files from folder: \(folderId)")
        
        let response: FileListResponse = try await networkManager.makeRequest(
            url: url,
            method: .GET,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ],
            responseType: FileListResponse.self
        )
        
        // Filter out null values from the response
        let validFiles = response.data.compactMap { $0 }
        print("📄 Fetched \(validFiles.count) files (filtered from \(response.data.count) total)")
        return validFiles
    }
    
    func downloadFile(fileId: String, to localURL: URL) async throws -> URL {
        guard let activeAccount = accountManager.activeAccount else {
            throw FileError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FileError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/files/\(fileId)/download") else {
            throw FileError.invalidURL
        }
        
        print("📥 Downloading file: \(fileId) to \(localURL.path)")
        
        let downloadedURL = try await networkManager.downloadFile(
            from: url,
            to: localURL,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/octet-stream"
            ]
        )
        
        print("📥 Downloaded file to: \(downloadedURL.path)")
        return downloadedURL
    }
    
    func uploadFile(from localURL: URL, to folderId: String, fileName: String) async throws -> FileMetadata {
        guard let activeAccount = accountManager.activeAccount else {
            throw FileError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FileError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/folders/\(folderId)/upload") else {
            throw FileError.invalidURL
        }
        
        print("📤 Uploading file: \(fileName) to folder: \(folderId)")
        
        let response: FileDetailResponse = try await networkManager.uploadFile(
            from: localURL,
            to: url,
            fileName: fileName,
            headers: [
                "Authorization": "Bearer \(token)"
            ],
            responseType: FileDetailResponse.self
        )
        
        print("📤 Uploaded file: \(response.data.name)")
        return response.data
    }
    
    func deleteFile(fileId: String) async throws {
        guard let activeAccount = accountManager.activeAccount else {
            throw FileError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FileError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/files/\(fileId)") else {
            throw FileError.invalidURL
        }
        
        print("🗑️ Deleting file: \(fileId)")
        
        let _: DeleteResponse = try await networkManager.makeRequest(
            url: url,
            method: .DELETE,
            headers: [
                "Authorization": "Bearer \(token)"
            ],
            responseType: DeleteResponse.self
        )
        
        print("🗑️ Deleted file: \(fileId)")
    }
    
    func getFileMetadata(fileId: String) async throws -> FileMetadata {
        guard let activeAccount = accountManager.activeAccount else {
            throw FileError.noActiveAccount
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        guard let token = KeychainManager.shared.retrieveToken(account: accountKey) else {
            throw FileError.noAuthToken
        }
        
        guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/files/\(fileId)") else {
            throw FileError.invalidURL
        }
        
        print("📄 Fetching file metadata: \(fileId)")
        
        let response: FileDetailResponse = try await networkManager.makeRequest(
            url: url,
            method: .GET,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ],
            responseType: FileDetailResponse.self
        )
        
        return response.data
    }
    
    // MARK: - Sync Operations
    
    func getFileChecksum(fileId: String) async throws -> String {
        let metadata = try await getFileMetadata(fileId: fileId)
        return metadata.checksum ?? ""
    }
    
    func validateFileIntegrity(fileId: String, localChecksum: String) async throws -> Bool {
        let remoteChecksum = try await getFileChecksum(fileId: fileId)
        return remoteChecksum == localChecksum
    }
}

// MARK: - Request/Response Models

struct FileListResponse: Codable {
    let status: Int
    let data: [FileMetadata?]
    let notifications: [String]
    let errors: [String]
}

struct FileDetailResponse: Codable {
    let status: Int
    let data: FileMetadata
    let notifications: [String]
    let errors: [String]
}

struct DeleteResponse: Codable {
    let status: Int
    let data: [String]
    let notifications: [String]
    let errors: [String]
}

// MARK: - Error Types

enum FileError: Error, LocalizedError {
    case noActiveAccount
    case noAuthToken
    case invalidURL
    case networkError(String)
    case serverError(String)
    case fileNotFound
    case permissionDenied
    case uploadFailed
    case downloadFailed
    case checksumMismatch
    
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
        case .fileNotFound:
            return "File not found"
        case .permissionDenied:
            return "Permission denied to access file"
        case .uploadFailed:
            return "File upload failed"
        case .downloadFailed:
            return "File download failed"
        case .checksumMismatch:
            return "File integrity check failed"
        }
    }
}
