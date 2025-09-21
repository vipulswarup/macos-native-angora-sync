import Foundation
import Combine

@MainActor
class FolderBrowserViewModel: ObservableObject {
    @Published var folders: [FolderMetadata] = []
    @Published var selectedFolders: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var expandedFolders: Set<String> = []
    @Published var currentPath: String = ""
    @Published var breadcrumbs: [Breadcrumb] = []
    
    private let folderService = FolderService()
    private let accountManager = AccountManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var filteredFolders: [FolderMetadata] {
        if searchText.isEmpty {
            return folders
        } else {
            return folders.filter { folder in
                folder.name.localizedCaseInsensitiveContains(searchText) ||
                folder.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var selectedFolderCount: Int {
        return selectedFolders.count
    }
    
    var canAddSelectedFolders: Bool {
        return !selectedFolders.isEmpty && !isLoading
    }
    
    // MARK: - Initialization
    
    init() {
        setupSearchBinding()
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                // Search is handled by computed property
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Folder Operations
    
    func loadFolders(parentId: String? = nil) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedFolders: [FolderMetadata]
            if let parentId = parentId {
                // Fetch children of a specific folder
                fetchedFolders = try await folderService.fetchFolderChildren(folderId: parentId)
            } else {
                // Fetch root-level folders (departments)
                fetchedFolders = try await folderService.fetchRootFolders()
            }
            folders = fetchedFolders.sorted { $0.name < $1.name }
            
            // Update current path and breadcrumbs
            if let parentId = parentId {
                await updatePathForParent(parentId)
            } else {
                currentPath = ""
                breadcrumbs = [Breadcrumb(name: "Root", id: nil)]
            }
            
            print("📁 Loaded \(folders.count) folders")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load folders: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshFolders() async {
        await loadFolders(parentId: breadcrumbs.last?.id)
    }
    
    func navigateToFolder(_ folder: FolderMetadata) async {
        // Add to breadcrumbs
        breadcrumbs.append(Breadcrumb(name: folder.name, id: folder.id))
        currentPath = folder.displayPath
        
        // Load subfolders
        await loadFolders(parentId: folder.id)
    }
    
    func navigateToBreadcrumb(_ breadcrumb: Breadcrumb) async {
        // Remove breadcrumbs after the selected one
        if let index = breadcrumbs.firstIndex(where: { $0.id == breadcrumb.id }) {
            breadcrumbs = Array(breadcrumbs.prefix(index + 1))
        }
        
        // Update current path
        if breadcrumb.id == nil {
            currentPath = ""
        } else {
            currentPath = breadcrumbs.dropFirst().map { $0.name }.joined(separator: "/")
        }
        
        // Load folders for the selected breadcrumb
        await loadFolders(parentId: breadcrumb.id)
    }
    
    private func updatePathForParent(_ parentId: String) async {
        // This would typically fetch the parent folder's path
        // For now, we'll build it from breadcrumbs
        currentPath = breadcrumbs.dropFirst().map { $0.name }.joined(separator: "/")
    }
    
    // MARK: - Selection Operations
    
    func toggleFolderSelection(_ folderId: String) {
        if selectedFolders.contains(folderId) {
            selectedFolders.remove(folderId)
        } else {
            selectedFolders.insert(folderId)
        }
    }
    
    func selectAllFolders() {
        selectedFolders = Set(filteredFolders.map { $0.id })
    }
    
    func deselectAllFolders() {
        selectedFolders.removeAll()
    }
    
    func isFolderSelected(_ folderId: String) -> Bool {
        return selectedFolders.contains(folderId)
    }
    
    func getSelectedFolders() -> [FolderMetadata] {
        return folders.filter { selectedFolders.contains($0.id) }
    }
    
    // MARK: - Sync Operations
    
    func addSelectedFoldersToSync() async {
        let selectedFolders = getSelectedFolders()
        guard !selectedFolders.isEmpty else { return }
        
        do {
            for folder in selectedFolders {
                try await addFolderToSync(folder)
            }
            
            // Clear selection after adding
            deselectAllFolders()
            
            print("✅ Added \(selectedFolders.count) folders to sync")
        } catch {
            errorMessage = "Failed to add folders to sync: \(error.localizedDescription)"
            print("❌ Failed to add folders to sync: \(error)")
        }
    }
    
    private func addFolderToSync(_ folder: FolderMetadata) async throws {
        guard let activeAccount = accountManager.activeAccount else {
            throw FolderError.noActiveAccount
        }
        
        // Create local folder path
        let localPath = createLocalFolderPath(for: folder, account: activeAccount)
        
        // Create sync folder
        let syncFolder = SyncFolder.create(
            remoteFolder: folder,
            accountId: activeAccount.id?.uuidString ?? "",
            localPath: localPath
        )
        
        // Save to Core Data (this would be implemented in a SyncFolderManager)
        // For now, we'll just print the sync folder
        print("📁 Created sync folder: \(syncFolder.displayName) -> \(syncFolder.localPath)")
    }
    
    private func createLocalFolderPath(for folder: FolderMetadata, account: SyncAccount) -> String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let basePath = homeDirectory.appendingPathComponent("EisenVault")
        let accountPath = basePath.appendingPathComponent(account.name ?? "Unknown")
        let folderPath = accountPath.appendingPathComponent(folder.displayPath)
        
        return folderPath.path
    }
    
    // MARK: - UI Operations
    
    func toggleFolderExpansion(_ folderId: String) {
        if expandedFolders.contains(folderId) {
            expandedFolders.remove(folderId)
        } else {
            expandedFolders.insert(folderId)
        }
    }
    
    func isFolderExpanded(_ folderId: String) -> Bool {
        return expandedFolders.contains(folderId)
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Breadcrumb Model

struct Breadcrumb: Identifiable, Hashable {
    let id: String?
    let name: String
    
    init(name: String, id: String?) {
        self.name = name
        self.id = id
    }
}
