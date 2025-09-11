# EisenVault Desktop Sync Client

A native macOS desktop sync client for EisenVault DMS that provides Dropbox-like functionality with two-way sync, multi-account support, and Finder integration.

## Sprint 1: Project Foundation & Basic Authentication ✅

### Deliverable
Working app with login functionality that can authenticate with the EisenVault backend and securely store credentials.

### Features Implemented

#### ✅ Authentication System
- **LoginView**: Clean, professional login interface with email/password fields
- **Server URL Configuration**: Users can specify custom server URLs
- **Password Visibility Toggle**: Show/hide password functionality
- **Loading States**: Visual feedback during authentication
- **Error Handling**: Clear error messages for failed login attempts

#### ✅ Secure Credential Storage
- **KeychainManager**: Secure storage of passwords and JWT tokens
- **Account-based Storage**: Separate credential stores per account
- **Token Management**: Automatic token storage and retrieval
- **Secure Deletion**: Proper cleanup of credentials on logout

#### ✅ API Integration
- **AuthService**: Complete authentication service with async/await
- **NetworkManager**: Robust HTTP client with error handling
- **Token Verification**: Automatic token validation on app launch
- **Network Monitoring**: Real-time connectivity status

#### ✅ Core Data Foundation
- **Account Model**: Core Data entity for user accounts
- **PersistenceController**: Proper Core Data stack setup
- **Data Relationships**: Foundation for future sync data models

#### ✅ App Architecture
- **SwiftUI**: Modern, declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **Combine Integration**: Reactive programming for state management
- **App Store Ready**: Proper entitlements and sandboxing

### Technical Implementation

#### Project Structure
```
EisenVaultSync/
├── App/
│   └── EisenVaultSyncApp.swift          # Main app entry point
├── Auth/
│   ├── AuthService.swift                # Authentication logic
│   ├── LoginView.swift                  # Login UI
│   └── AuthModels.swift                 # Auth data models
├── Core/
│   ├── KeychainManager.swift            # Secure credential storage
│   ├── NetworkManager.swift             # HTTP client
│   ├── PersistenceController.swift      # Core Data stack
│   └── Models/
│       └── Account.swift                # Account Core Data model
└── ContentView.swift                    # Main app view
```

#### Key Components

**AuthService**
- Handles login/logout operations
- Manages JWT token lifecycle
- Provides authentication state to UI
- Integrates with Keychain for secure storage

**KeychainManager**
- Secure storage using macOS Keychain Services
- Account-based credential isolation
- Token and password management
- Proper cleanup on logout

**NetworkManager**
- Modern async/await HTTP client
- Comprehensive error handling
- Network connectivity monitoring
- Generic request/response handling

**LoginView**
- Professional, accessible UI design
- Real-time validation and feedback
- Loading states and error display
- Server URL configuration

### API Integration

The app integrates with the EisenVault backend using the following endpoints:

- `POST /api/auth/login` - User authentication
- `POST /api/auth/token` - Token verification
- `POST /api/auth/logout` - Session termination

### Security Features

- **Sandboxed Application**: Proper macOS app sandboxing
- **Keychain Integration**: Secure credential storage
- **HTTPS Support**: Secure communication with backend
- **Token-based Auth**: JWT token authentication
- **Credential Isolation**: Separate storage per account

### Acceptance Criteria Met

- [x] App launches and displays login screen
- [x] User can authenticate with valid credentials
- [x] Credentials are stored securely in Keychain
- [x] Invalid credentials show appropriate error message
- [x] App remembers login state between launches
- [x] Professional, accessible user interface
- [x] Proper error handling and user feedback
- [x] Network connectivity monitoring

### Next Steps (Sprint 2)

The foundation is now ready for Sprint 2, which will add:
- Multi-account management
- Account switching functionality
- Account setup and management UI
- Enhanced navigation structure

### Running the App

1. Open `EisenVaultSync.xcodeproj` in Xcode
2. Ensure the EisenVault backend is running on `http://localhost:6001`
3. Build and run the app (⌘+R)
4. Use valid credentials to test authentication

**Note:** The project file has been fixed and all compilation errors have been resolved. The app builds successfully and is ready for development.

### Development Notes

- Built for macOS 13.0+ (SwiftUI requirements)
- Uses modern async/await patterns
- Follows Apple's Human Interface Guidelines
- Implements proper accessibility support
- Ready for App Store submission (entitlements configured)

---

**Sprint 1 Status: ✅ COMPLETED**
**Next Sprint: Multi-Account Management & Basic UI**
