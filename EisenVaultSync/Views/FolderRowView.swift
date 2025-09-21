import SwiftUI

struct FolderRowView: View {
    let folder: FolderMetadata
    let isSelected: Bool
    let isExpanded: Bool
    let canNavigate: Bool
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
            if canNavigate {
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
                rawFileName: "Documents",
                description: "Documents folder",
                parentPath: nil,
                materializePath: "/Documents",
                originalCloudRelativePath: nil,
                convertedCloudRelativePath: nil,
                documentCategory: nil,
                dataEntry: nil,
                size: 1024 * 1024 * 5, // 5MB
                portal: "web",
                fileCount: 15,
                collaborators: nil,
                isBeingTrashed: false,
                isBeingMoved: false,
                isBeingCopied: false,
                isDepartment: false,
                isFolder: true,
                isFile: false,
                isLocked: false,
                createdBy: "user1",
                editedBy: "user1",
                ocrLanguages: [],
                isConvertable: false,
                isConverted: false,
                errorList: [],
                relatedFiles: [],
                createdAt: Date(),
                updatedAt: Date(),
                version: nil,
                extension: nil,
                watermarkedLink: nil,
                upload: nil
            ),
            isSelected: false,
            isExpanded: false,
            canNavigate: true,
            onSelectionToggle: {},
            onExpansionToggle: {},
            onNavigate: {}
        )
        
        FolderRowView(
            folder: FolderMetadata(
                id: "2",
                rawFileName: "Shared Folder",
                description: "Shared folder",
                parentPath: nil,
                materializePath: "/Shared Folder",
                originalCloudRelativePath: nil,
                convertedCloudRelativePath: nil,
                documentCategory: nil,
                dataEntry: nil,
                size: 1024 * 1024 * 2, // 2MB
                portal: "web",
                fileCount: 8,
                collaborators: [Collaborator(buffer: "user1"), Collaborator(buffer: "user2")],
                isBeingTrashed: false,
                isBeingMoved: false,
                isBeingCopied: false,
                isDepartment: false,
                isFolder: true,
                isFile: false,
                isLocked: false,
                createdBy: "user1",
                editedBy: "user1",
                ocrLanguages: [],
                isConvertable: false,
                isConverted: false,
                errorList: [],
                relatedFiles: [],
                createdAt: Date(),
                updatedAt: Date(),
                version: nil,
                extension: nil,
                watermarkedLink: nil,
                upload: nil
            ),
            isSelected: true,
            isExpanded: false,
            canNavigate: false,
            onSelectionToggle: {},
            onExpansionToggle: {},
            onNavigate: {}
        )
    }
    .padding()
}
