import SwiftUI

struct FolderBrowserView: View {
    @StateObject private var viewModel = FolderBrowserViewModel()
    @EnvironmentObject var accountManager: AccountManager
    @State private var showingAddToSyncAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Breadcrumb navigation
            if !viewModel.breadcrumbs.isEmpty {
                breadcrumbView
                Divider()
            }
            
            // Search bar
            searchView
            
            Divider()
            
            // Folder list
            folderListView
            
            // Footer
            footerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            await viewModel.loadFolders()
        }
        .alert("Add to Sync", isPresented: $showingAddToSyncAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Add \(viewModel.selectedFolderCount) Folder(s)") {
                Task {
                    await viewModel.addSelectedFoldersToSync()
                }
            }
        } message: {
            Text("Add the selected folders to sync? This will create local copies and enable two-way synchronization.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Folder Browser")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    if let activeAccount = accountManager.activeAccount {
                        Text("Account: \(activeAccount.name ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.currentLevelTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Refresh") {
                Task {
                    await viewModel.refreshFolders()
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
    
    // MARK: - Breadcrumb View
    
    private var breadcrumbView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.breadcrumbs) { breadcrumb in
                    Button(action: {
                        Task {
                            await viewModel.navigateToBreadcrumb(breadcrumb)
                        }
                    }) {
                        HStack(spacing: 4) {
                            if breadcrumb.id != nil {
                                Image(systemName: "folder")
                                    .font(.caption)
                            } else {
                                Image(systemName: "house")
                                    .font(.caption)
                            }
                            
                            Text(breadcrumb.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if breadcrumb.id != viewModel.breadcrumbs.last?.id {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Search View
    
    private var searchView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search folders...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button("Clear") {
                    viewModel.searchText = ""
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Folder List View
    
    private var folderListView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredFolders.isEmpty {
                emptyView
            } else {
                folderList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading folders...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(viewModel.searchText.isEmpty ? "No folders found" : "No folders match your search")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if viewModel.searchText.isEmpty {
                Text("This folder is empty or you don't have permission to view its contents")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var folderList: some View {
        List {
            ForEach(viewModel.filteredFolders) { folder in
                FolderRowView(
                    folder: folder,
                    isSelected: viewModel.isFolderSelected(folder.id),
                    isExpanded: viewModel.isFolderExpanded(folder.id),
                    canNavigate: viewModel.canNavigateIntoFolder(folder),
                    onSelectionToggle: {
                        viewModel.toggleFolderSelection(folder.id)
                    },
                    onExpansionToggle: {
                        viewModel.toggleFolderExpansion(folder.id)
                    },
                    onNavigate: {
                        Task {
                            await viewModel.navigateToFolder(folder)
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        VStack(spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.filteredFolders.count) \(viewModel.currentLevelTitle.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.selectedFolderCount > 0 {
                        Text(viewModel.getSelectedItemsDescription())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if viewModel.selectedFolderCount > 0 {
                        Button("Deselect All") {
                            viewModel.deselectAllFolders()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Add to Sync") {
                            showingAddToSyncAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canAddSelectedFolders)
                    } else {
                        Button("Select All") {
                            viewModel.selectAllFolders()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.filteredFolders.isEmpty)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button("Dismiss") {
                viewModel.clearError()
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    FolderBrowserView()
        .environmentObject(AccountManager.shared)
        .frame(width: 600, height: 500)
}
