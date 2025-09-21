import SwiftUI

struct FolderRowView: View {
    let folder: FolderMetadata
    let isSelected: Bool
    let isExpanded: Bool
    let onSelectionToggle: () -> Void
    let onExpansionToggle: () -> Void
    let onNavigate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onSelectionToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Folder icon
            Image(systemName: folderIcon)
                .foregroundColor(folderColor)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)
            
            // Folder info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(folder.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if folder.isShared {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Text(folder.displayPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(folder.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Folder stats
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    if folder.folderCount > 0 {
                        Label("\(folder.folderCount)", systemImage: "folder")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if folder.fileCount > 0 {
                        Label("\(folder.fileCount)", systemImage: "doc")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(folder.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Navigation arrow
            if folder.folderCount > 0 {
                Button(action: onNavigate) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectionToggle()
        }
        .contextMenu {
            FolderContextMenu(folder: folder)
        }
    }
    
    // MARK: - Computed Properties
    
    private var folderIcon: String {
        if folder.isShared {
            return "folder.badge.person.crop"
        } else {
            return "folder"
        }
    }
    
    private var folderColor: Color {
        if folder.isShared {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Context Menu

struct FolderContextMenu: View {
    let folder: FolderMetadata
    
    var body: some View {
        Group {
            Button("Open in Finder") {
                // TODO: Implement Finder integration
            }
            
            Button("View Details") {
                // TODO: Implement folder details view
            }
            
            Divider()
            
            if folder.canEdit {
                Button("Rename") {
                    // TODO: Implement rename functionality
                }
            }
            
            if folder.canDelete {
                Button("Delete", role: .destructive) {
                    // TODO: Implement delete functionality
                }
            }
            
            Divider()
            
            Button("Add to Sync") {
                // TODO: Implement add to sync
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        FolderRowView(
            folder: FolderMetadata(
                id: "1",
                name: "Documents",
                parentId: nil,
                path: "",
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "user1",
                updatedBy: "user1",
                permissions: ["list_folder_content", "download_document"],
                isShared: false,
                shareSettings: nil,
                metadata: [:],
                fileCount: 15,
                folderCount: 3,
                totalSize: 1024 * 1024 * 5 // 5MB
            ),
            isSelected: false,
            isExpanded: false,
            onSelectionToggle: {},
            onExpansionToggle: {},
            onNavigate: {}
        )
        
        FolderRowView(
            folder: FolderMetadata(
                id: "2",
                name: "Shared Folder",
                parentId: nil,
                path: "",
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: "user1",
                updatedBy: "user1",
                permissions: ["list_folder_content", "download_document"],
                isShared: true,
                shareSettings: nil,
                metadata: [:],
                fileCount: 8,
                folderCount: 1,
                totalSize: 1024 * 1024 * 2 // 2MB
            ),
            isSelected: true,
            isExpanded: false,
            onSelectionToggle: {},
            onExpansionToggle: {},
            onNavigate: {}
        )
    }
    .padding()
}
