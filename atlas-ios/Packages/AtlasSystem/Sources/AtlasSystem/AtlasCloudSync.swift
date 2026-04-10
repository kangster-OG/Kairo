import AtlasDomain
import AuthenticationServices
#if canImport(CryptoKit)
import CryptoKit
#endif
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct AtlasCloudConfiguration: Sendable, Equatable {
    public var projectURL: URL
    public var anonKey: String

    public init(projectURL: URL, anonKey: String) {
        self.projectURL = projectURL
        self.anonKey = anonKey
    }

    public static func environment(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> Self? {
        let rawURL = (environment["ATLAS_SUPABASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
            $0.isEmpty ? nil : $0
        } ?? (bundleInfo["ATLAS_SUPABASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let anonKey = (environment["ATLAS_SUPABASE_ANON_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
            $0.isEmpty ? nil : $0
        } ?? (bundleInfo["ATLAS_SUPABASE_ANON_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let rawURL,
              let url = URL(string: rawURL),
              let anonKey,
              anonKey.isEmpty == false else {
            return nil
        }

        return Self(projectURL: url, anonKey: anonKey)
    }
}

public struct AtlasCloudSessionSnapshot: Sendable, Equatable {
    public var email: String
    public var userID: String
    public var lastSyncAt: Date?

    public init(email: String, userID: String, lastSyncAt: Date? = nil) {
        self.email = email
        self.userID = userID
        self.lastSyncAt = lastSyncAt
    }
}

public struct AtlasLiveReviewSessionSnapshot: Sendable, Equatable {
    public var id: String
    public var shareURL: URL
    public var expiresAt: Date?

    public init(id: String, shareURL: URL, expiresAt: Date?) {
        self.id = id
        self.shareURL = shareURL
        self.expiresAt = expiresAt
    }
}

public enum AtlasCloudIdentityProvider: String, Sendable, Equatable {
    case google
    case apple

    public var oauthProviderName: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }

    var requestedScopes: String {
        switch self {
        case .google:
            return "email profile"
        case .apple:
            return "name email"
        }
    }
}

public protocol CloudSyncManaging: Sendable {
    func isConfigured() -> Bool
    func currentSession() async -> AtlasCloudSessionSnapshot?
    func signUp(email: String, password: String) async throws -> AtlasCloudSessionSnapshot
    func signIn(email: String, password: String) async throws -> AtlasCloudSessionSnapshot
    func signIn(with provider: AtlasCloudIdentityProvider) async throws -> AtlasCloudSessionSnapshot
    func signOut() async throws
    func uploadExportBundle(_ data: Data, generatedAt: Date, deviceID: String?) async throws -> AtlasCloudSessionSnapshot
    func downloadLatestExportBundle() async throws -> Data?
    func createLiveReviewSession(
        title: String,
        request: AtlasReviewRequest,
        workspace: AtlasReviewWorkspace
    ) async throws -> AtlasLiveReviewSessionSnapshot
    func revokeLiveReviewSession(id: String) async throws
    func statusDescription() async -> String
}

public final class AtlasSupabaseCloudSyncManager: CloudSyncManaging, @unchecked Sendable {
    private let configuration: AtlasCloudConfiguration?
    private let urlSession: URLSession
    private let defaults: UserDefaults
    private let storageKey = "atlas.cloud.session"

    public init(
        configuration: AtlasCloudConfiguration? = .environment(),
        urlSession: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
        self.defaults = defaults
    }

    public func isConfigured() -> Bool {
        configuration != nil
    }

    public func currentSession() async -> AtlasCloudSessionSnapshot? {
        storedSession()?.snapshot
    }

    public func signUp(email: String, password: String) async throws -> AtlasCloudSessionSnapshot {
        try await authenticate(
            path: "/auth/v1/signup",
            queryItems: [],
            body: [
                "email": email,
                "password": password
            ],
            allowPendingConfirmation: true
        )
    }

    public func signIn(email: String, password: String) async throws -> AtlasCloudSessionSnapshot {
        try await authenticate(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: [
                "email": email,
                "password": password
            ]
        )
    }

    public func signIn(with provider: AtlasCloudIdentityProvider) async throws -> AtlasCloudSessionSnapshot {
        switch provider {
        case .apple:
            return try await signInWithApple()
        case .google:
            return try await signInWithOAuth(provider: provider)
        }
    }

    private func signInWithOAuth(provider: AtlasCloudIdentityProvider) async throws -> AtlasCloudSessionSnapshot {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }

        var components = URLComponents(
            url: configuration.projectURL.appending(path: "/auth/v1/authorize"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "provider", value: provider.oauthProviderName),
            URLQueryItem(name: "redirect_to", value: Self.oauthRedirectURL.absoluteString),
            URLQueryItem(name: "scopes", value: provider.requestedScopes)
        ]

        guard let url = components?.url else {
            throw AtlasCloudSyncError.invalidConfiguration
        }

        let callbackURL = try await AtlasOAuthSessionBroker.authenticate(
            startingAt: url,
            callbackScheme: Self.oauthRedirectScheme
        )
        return try await importOAuthSession(from: callbackURL)
    }

    private func signInWithApple() async throws -> AtlasCloudSessionSnapshot {
        let credential = try await AtlasAppleSignInBroker.authenticate()
        return try await authenticateWithIDToken(
            provider: .apple,
            idToken: credential.identityToken,
            nonce: credential.rawNonce
        )
    }

    public func signOut() async throws {
        guard let configuration, let session = storedSession() else {
            clearStoredSession()
            return
        }

        var request = URLRequest(url: configuration.projectURL.appending(path: "/auth/v1/logout"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        _ = try await perform(request)
        clearStoredSession()
    }

    public func uploadExportBundle(_ data: Data, generatedAt: Date, deviceID: String?) async throws -> AtlasCloudSessionSnapshot {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }
        guard let session = storedSession() else {
            throw AtlasCloudSyncError.notAuthenticated
        }

        let payload: [String: AnySendable] = [
            "owner_id": .string(session.userID),
            "export_bundle": .rawJSON(data),
            "manifest_generated_at": .string(ISO8601DateFormatter().string(from: generatedAt)),
            "device_id": .string(deviceID ?? "")
        ]

        var components = URLComponents(url: configuration.projectURL.appending(path: "/rest/v1/atlas_account_snapshots"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "on_conflict", value: "owner_id")]

        guard let url = components?.url else {
            throw AtlasCloudSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try AnySendable.encodeJSONArray([payload])

        _ = try await perform(request)

        var updated = session
        updated.lastSyncAt = generatedAt
        persist(updated)
        return updated.snapshot
    }

    public func downloadLatestExportBundle() async throws -> Data? {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }
        guard let session = storedSession() else {
            throw AtlasCloudSyncError.notAuthenticated
        }

        var components = URLComponents(url: configuration.projectURL.appending(path: "/rest/v1/atlas_account_snapshots"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "select", value: "export_bundle"),
            URLQueryItem(name: "owner_id", value: "eq.\(session.userID)")
        ]

        guard let url = components?.url else {
            throw AtlasCloudSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await perform(request)
        let response = try JSONDecoder().decode([AtlasSnapshotEnvelope].self, from: data)
        return response.first?.exportBundle
    }

    public func createLiveReviewSession(
        title: String,
        request: AtlasReviewRequest,
        workspace: AtlasReviewWorkspace
    ) async throws -> AtlasLiveReviewSessionSnapshot {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }
        guard let session = storedSession() else {
            throw AtlasCloudSyncError.notAuthenticated
        }

        let workspaceData = try JSONEncoder().encode(workspace)
        let expiresAt = request.expiresAt.map { ISO8601DateFormatter().string(from: $0) }
        let payload: [String: AnySendable] = [
            "title": .string(title),
            "scope_kind": .string(request.scopeKind.rawValue),
            "render_mode": .string(workspace.renderMode.rawValue),
            "row_count": .number(workspace.rowCount),
            "summary": .string(workspace.summary),
            "workspace_json": .rawJSON(workspaceData),
            "expires_at": expiresAt.map(AnySendable.string) ?? .null
        ]

        var request = URLRequest(url: configuration.projectURL.appending(path: "/functions/v1/live-review-session"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try AnySendable.encodeJSONObject(payload)

        let (data, _) = try await perform(request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(AtlasLiveReviewCreateResponse.self, from: data)
        return AtlasLiveReviewSessionSnapshot(
            id: response.session.id,
            shareURL: response.session.shareURL,
            expiresAt: response.session.expiresAt
        )
    }

    public func revokeLiveReviewSession(id: String) async throws {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }
        guard let session = storedSession() else {
            throw AtlasCloudSyncError.notAuthenticated
        }

        var components = URLComponents(url: configuration.projectURL.appending(path: "/functions/v1/live-review-session"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "session_id", value: id)]
        guard let url = components?.url else {
            throw AtlasCloudSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        _ = try await perform(request)
    }

    public func statusDescription() async -> String {
        guard configuration != nil else {
            return "Cloud sync is not configured yet. Atlas continues to work locally."
        }
        if let session = storedSession()?.snapshot {
            if let lastSyncAt = session.lastSyncAt {
                return "Signed in as \(session.email). Last sync \(lastSyncAt.formatted(date: .abbreviated, time: .shortened))."
            }
            return "Signed in as \(session.email)."
        }
        return "Cloud sync is configured and ready for sign-in."
    }

    private func authenticate(
        path: String,
        queryItems: [URLQueryItem],
        body: [String: String],
        allowPendingConfirmation: Bool = false
    ) async throws -> AtlasCloudSessionSnapshot {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }

        var components = URLComponents(url: configuration.projectURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw AtlasCloudSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await perform(request)
        let response = try JSONDecoder().decode(AtlasAuthResponse.self, from: data)
        guard let accessToken = response.accessToken,
              let refreshToken = response.refreshToken else {
            if allowPendingConfirmation {
                throw AtlasCloudSyncError.confirmationRequired(response.user.email)
            }
            throw AtlasCloudSyncError.invalidResponse
        }
        let session = StoredSession(
            email: response.user.email,
            userID: response.user.id,
            accessToken: accessToken,
            refreshToken: refreshToken,
            lastSyncAt: nil
        )
        persist(session)
        return session.snapshot
    }

    private func authenticateWithIDToken(
        provider: AtlasCloudIdentityProvider,
        idToken: String,
        nonce: String
    ) async throws -> AtlasCloudSessionSnapshot {
        try await authenticate(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: [
                "provider": provider.oauthProviderName,
                "id_token": idToken,
                "nonce": nonce
            ]
        )
    }

    private func importOAuthSession(from callbackURL: URL) async throws -> AtlasCloudSessionSnapshot {
        guard let configuration else {
            throw AtlasCloudSyncError.notConfigured
        }

        let parameters = oauthParameters(from: callbackURL)
        if let description = parameters["error_description"], description.isEmpty == false {
            throw AtlasCloudSyncError.requestFailed(description)
        }
        if let error = parameters["error"], error.isEmpty == false {
            throw AtlasCloudSyncError.requestFailed(error)
        }

        guard let accessToken = parameters["access_token"], accessToken.isEmpty == false,
              let refreshToken = parameters["refresh_token"], refreshToken.isEmpty == false else {
            throw AtlasCloudSyncError.invalidResponse
        }

        var request = URLRequest(url: configuration.projectURL.appending(path: "/auth/v1/user"))
        request.httpMethod = "GET"
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await perform(request)
        let user = try JSONDecoder().decode(AtlasAuthResponse.User.self, from: data)

        let session = StoredSession(
            email: user.email,
            userID: user.id,
            accessToken: accessToken,
            refreshToken: refreshToken,
            lastSyncAt: nil
        )
        persist(session)
        return session.snapshot
    }

    private func oauthParameters(from callbackURL: URL) -> [String: String] {
        var parameters: [String: String] = [:]

        if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                parameters[item.name] = item.value ?? ""
            }
        }

        if let fragment = callbackURL.fragment,
           let components = URLComponents(string: "https://atlas.local/oauth?\(fragment)") {
            for item in components.queryItems ?? [] {
                parameters[item.name] = item.value ?? ""
            }
        }

        return parameters
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AtlasCloudSyncError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AtlasCloudSyncError.requestFailed(String(decoding: data, as: UTF8.self))
        }
        return (data, http)
    }

    private func storedSession() -> StoredSession? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    private func persist(_ session: StoredSession) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func clearStoredSession() {
        defaults.removeObject(forKey: storageKey)
    }

    private static let oauthRedirectScheme = "atlas"
    private static let oauthRedirectURL = URL(string: "atlas://auth/callback")!
}

private enum AtlasCloudSyncError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case invalidConfiguration
    case invalidResponse
    case confirmationRequired(String)
    case requestFailed(String)
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloud sync is not configured for this build."
        case .notAuthenticated:
            return "Sign in to Atlas cloud sync before using this feature."
        case .invalidConfiguration:
            return "Cloud sync configuration is invalid."
        case .invalidResponse:
            return "Cloud sync returned an invalid response."
        case .confirmationRequired(let email):
            return "Atlas created \(email), but email confirmation is still required before this device can sync."
        case .requestFailed(let message):
            return message.isEmpty ? "Cloud sync request failed." : message
        case .userCancelled:
            return "Sign-in was cancelled before Atlas received a session."
        }
    }
}

private struct StoredSession: Codable, Sendable, Equatable {
    var email: String
    var userID: String
    var accessToken: String
    var refreshToken: String
    var lastSyncAt: Date?

    var snapshot: AtlasCloudSessionSnapshot {
        AtlasCloudSessionSnapshot(email: email, userID: userID, lastSyncAt: lastSyncAt)
    }
}

private struct AtlasAuthResponse: Codable, Sendable {
    struct User: Codable, Sendable {
        var id: String
        var email: String
    }

    var accessToken: String?
    var refreshToken: String?
    var user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

private struct AtlasSnapshotEnvelope: Decodable, Sendable {
    var exportBundle: Data

    enum CodingKeys: String, CodingKey {
        case exportBundle = "export_bundle"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawObject = try container.decode(JSONValue.self, forKey: .exportBundle)
        exportBundle = try JSONEncoder().encode(rawObject)
    }
}

private struct AtlasLiveReviewCreateResponse: Codable, Sendable {
    struct Session: Codable, Sendable {
        var id: String
        var shareURL: URL
        var expiresAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case shareURL = "share_url"
            case expiresAt = "expires_at"
        }
    }

    var session: Session
}

private struct AtlasAppleIdentityCredential: Sendable, Equatable {
    var identityToken: String
    var rawNonce: String
}

@MainActor
private final class AtlasOAuthSessionBroker: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var continuation: CheckedContinuation<URL, Error>?
    private var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if canImport(UIKit)
        let connectedScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in connectedScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        return connectedScenes.first?.windows.first ?? ASPresentationAnchor()
#elseif canImport(AppKit)
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
#else
        return ASPresentationAnchor()
#endif
    }

    func start(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                guard let self else { return }
                defer {
                    self.session = nil
                    self.continuation = nil
                }

                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else if let authError = error as? ASWebAuthenticationSessionError,
                          authError.code == .canceledLogin {
                    continuation.resume(throwing: AtlasCloudSyncError.userCancelled)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: AtlasCloudSyncError.invalidResponse)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }

    static func authenticate(startingAt url: URL, callbackScheme: String) async throws -> URL {
        try await AtlasOAuthSessionBroker().start(url: url, callbackScheme: callbackScheme)
    }
}

@MainActor
private final class AtlasAppleSignInBroker: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AtlasAppleIdentityCredential, Error>?
    private var rawNonce = ""

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if canImport(UIKit)
        let connectedScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in connectedScenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }
        }
        return connectedScenes.first?.windows.first ?? ASPresentationAnchor()
#elseif canImport(AppKit)
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
#else
        return ASPresentationAnchor()
#endif
    }

    func start() async throws -> AtlasAppleIdentityCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            rawNonce = Self.randomNonce()

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(rawNonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { continuation = nil }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              identityToken.isEmpty == false else {
            continuation?.resume(throwing: AtlasCloudSyncError.invalidResponse)
            return
        }

        continuation?.resume(
            returning: AtlasAppleIdentityCredential(identityToken: identityToken, rawNonce: rawNonce)
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer { continuation = nil }

        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            continuation?.resume(throwing: AtlasCloudSyncError.userCancelled)
            return
        }

        continuation?.resume(throwing: error)
    }

    static func authenticate() async throws -> AtlasAppleIdentityCredential {
        try await AtlasAppleSignInBroker().start()
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randomBytes = (0..<16).map { _ in UInt8.random(in: .min ... .max) }
            for byte in randomBytes {
                guard remainingLength > 0 else { break }
                if Int(byte) < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
#if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
#else
        return input
#endif
    }
}

private enum AnySendable: Sendable {
    case string(String)
    case number(Int)
    case rawJSON(Data)
    case null

    static func encodeJSONArray(_ rows: [[String: AnySendable]]) throws -> Data {
        let jsonRows = rows.map { row in
            encodeJSONObjectObject(row)
        }
        return try JSONSerialization.data(withJSONObject: jsonRows, options: [.sortedKeys])
    }

    static func encodeJSONObject(_ row: [String: AnySendable]) throws -> Data {
        try JSONSerialization.data(withJSONObject: encodeJSONObjectObject(row), options: [.sortedKeys])
    }

    private static func encodeJSONObjectObject(_ row: [String: AnySendable]) -> [String: Any] {
        row.reduce(into: [String: Any]()) { partialResult, element in
            switch element.value {
            case .string(let value):
                partialResult[element.key] = value
            case .number(let value):
                partialResult[element.key] = value
            case .rawJSON(let value):
                partialResult[element.key] = try? JSONSerialization.jsonObject(with: value)
            case .null:
                partialResult[element.key] = NSNull()
            }
        }
    }
}

private enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
