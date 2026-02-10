//
//  GmailService.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation
import AuthenticationServices
import Combine
import GoogleSignIn
import UIKit

@MainActor
final class GmailService: NSObject, ObservableObject {

    static let shared = GmailService()

    @Published var isConnected = false
    @Published var errorMessage: String?
    // Added: holds parsed subscription emails discovered from Gmail
    @Published var scannedEmails: [ParsedEmailSubscription] = []
    // Optional: track scanning state used by SettingsView
    @Published var isScanning: Bool = false

    private let gmailConnectedKey = "gmailConnected"
    private let userDefaults = UserDefaults.standard

    override init() {
        super.init()
        // Prefer currentUser presence; fall back to stored flag
        if GIDSignIn.sharedInstance.currentUser != nil {
            isConnected = true
            userDefaults.set(true, forKey: gmailConnectedKey)
        } else {
            isConnected = userDefaults.bool(forKey: gmailConnectedKey)
        }
    }

    // MARK: - Connect Gmail (SwiftUI Safe)

    func connectGmail() async throws {

        guard let presentingVC = UIApplication.shared.rootViewController else {
            throw GmailError.authenticationFailed
        }

        let scopes = [
            "https://www.googleapis.com/auth/gmail.readonly"
        ]

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingVC,
                hint: nil,
                additionalScopes: scopes
            )

            // Access token (could store in Keychain if desired)
            let _ = result.user.accessToken.tokenString

            isConnected = true
            userDefaults.set(true, forKey: gmailConnectedKey)

        } catch {
            errorMessage = error.localizedDescription
            throw GmailError.authenticationFailed
        }
    }

    func disconnectGmail() {
        GIDSignIn.sharedInstance.signOut()
        isConnected = false
        userDefaults.set(false, forKey: gmailConnectedKey)
        // Clear any scanned results on disconnect
        scannedEmails.removeAll()
    }

    // MARK: - Token Handling

    private func currentUser() -> GIDGoogleUser? {
        GIDSignIn.sharedInstance.currentUser
    }

    /// Returns a valid access token string, refreshing it if necessary.
    private func validAccessToken() async throws -> String {
        guard let user = currentUser() else {
            throw GmailError.authenticationFailed
        }

        // If token is still valid, return it
        if !user.accessToken.tokenString.isEmpty,
           user.accessToken.expirationDate?.timeIntervalSinceNow ?? 0 > 60 {
            return user.accessToken.tokenString
        }

        // Otherwise refresh
        do {
            let refreshedUser = try await user.refreshTokensIfNeeded()
            return refreshedUser.accessToken.tokenString
        } catch {
            // Try interactive sign-in again if refresh fails
            isConnected = false
            userDefaults.set(false, forKey: gmailConnectedKey)
            throw GmailError.authenticationFailed
        }
    }

    // MARK: - Scanning placeholder (used in SettingsView)
    func scanEmails() async throws {
        let token = try await validAccessToken()

        isScanning = true
        errorMessage = nil

        let query = "subject:(receipt OR subscription OR renewal)"
        let urlString =
        "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(query)&maxResults=20"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            isScanning = false
            throw GmailError.apiError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        _ = try await URLSession.shared.data(for: request)

        // ⚠️ For v1, just fake results
        await MainActor.run {
            self.scannedEmails = []
            self.isScanning = false
        }
    }


    // MARK: - Manual parsing helpers used by ManualEmailEntryView

    func parseManualEmail(subject: String, content: String) -> ParsedEmailSubscription? {
        EmailParser.parseSubscription(from: content, subject: subject)
    }

    func addManualEmail(_ parsed: ParsedEmailSubscription) {
        scannedEmails.append(parsed)
    }
}

struct GmailMessage {
    let id: String
    let subject: String
    let body: String
    let date: Date
}

enum GmailError: LocalizedError {
    case notConnected
    case notImplemented(String)
    case apiError(String)
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Gmail is not connected. Please connect your Gmail account first."
        case .notImplemented(let message):
            return "Gmail integration not fully implemented: \(message)"
        case .apiError(let message):
            return "Gmail API error: \(message)"
        case .authenticationFailed:
            return "Failed to authenticate with Gmail. Please try connecting again."
        }
    }
}

