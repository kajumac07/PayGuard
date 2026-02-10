//
//  CalendarService.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation
internal import EventKit
import EventKitUI
import Combine

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var reminderDaysBefore: Int = 3
    
    private let eventStore = EKEventStore()
    private let calendarTitle = "PayGuard Subscriptions"
    
    private init() {
        checkAuthorizationStatus()
        loadReminderDays()
    }
    
    // Convenience to reflect whether we have any usable access to events
    var hasEventAccess: Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        if #available(iOS 17.0, *) {
            // On iOS 17+, authorizationStatus(for: .event) remains the correct API for events
            let status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .notDetermined:
                authorizationStatus = .notDetermined
            case .restricted:
                authorizationStatus = .restricted
            case .denied:
                authorizationStatus = .denied
            case .authorized:
                authorizationStatus = .authorized
            @unknown default:
                authorizationStatus = .notDetermined
            }
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return granted
            } catch {
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return false
            }
        } else {
            // Deprecated on iOS 17, but still valid for earlier OS versions
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return granted
            } catch {
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return false
            }
        }
    }
    
    // MARK: - Calendar Event Management
    
    func createOrUpdateEvent(for subscription: Subscription) async throws -> String? {
        guard subscription.syncToCalendar && subscription.isActive && !subscription.isCancelled else {
            // If sync is disabled or subscription is cancelled, remove existing event
            if let eventId = subscription.calendarEventId {
                try await deleteEvent(eventId: eventId)
            }
            return nil
        }
        
        // Check authorization
        guard hasEventAccess else {
            throw CalendarError.notAuthorized
        }
        
        let eventId: String
        
        if let existingEventId = subscription.calendarEventId,
           let existingEvent = eventStore.event(withIdentifier: existingEventId) {
            // Update existing event
            existingEvent.title = "\(subscription.name) - ₹\(String(format: "%.0f", subscription.amount))"
            existingEvent.startDate = subscription.nextDebitDate
            existingEvent.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: subscription.nextDebitDate) ?? subscription.nextDebitDate
            existingEvent.notes = "Subscription renewal for \(subscription.name)\nAmount: \(subscription.formattedAmount)\nFrequency: \(subscription.frequency.rawValue)"
            existingEvent.alarms = [createAlarm(daysBefore: reminderDaysBefore)]
            
            do {
                try eventStore.save(existingEvent, span: .thisEvent, commit: true)
                eventId = existingEventId
            } catch {
                throw CalendarError.saveFailed(error)
            }
        } else {
            // Create new event
            let event = EKEvent(eventStore: eventStore)
            event.title = "\(subscription.name) - ₹\(String(format: "%.0f", subscription.amount))"
            event.startDate = subscription.nextDebitDate
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: subscription.nextDebitDate) ?? subscription.nextDebitDate
            event.notes = "Subscription renewal for \(subscription.name)\nAmount: \(subscription.formattedAmount)\nFrequency: \(subscription.frequency.rawValue)"
            event.calendar = eventStore.defaultCalendarForNewEvents
            event.alarms = [createAlarm(daysBefore: reminderDaysBefore)]
            
            do {
                try eventStore.save(event, span: .thisEvent, commit: true)
                eventId = event.eventIdentifier
            } catch {
                throw CalendarError.saveFailed(error)
            }
        }
        
        return eventId
    }
    
    func deleteEvent(eventId: String) async throws {
        guard let event = eventStore.event(withIdentifier: eventId) else {
            return // Event doesn't exist, nothing to delete
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
        } catch {
            throw CalendarError.deleteFailed(error)
        }
    }
    
    private func createAlarm(daysBefore: Int) -> EKAlarm {
        let alarm = EKAlarm()
        alarm.relativeOffset = TimeInterval(-daysBefore * 24 * 60 * 60) // Negative for reminder before
        return alarm
    }
    
    // MARK: - Settings
    
    func setReminderDays(_ days: Int) {
        reminderDaysBefore = max(1, min(30, days)) // Clamp between 1-30 days
        UserDefaults.standard.set(reminderDaysBefore, forKey: "calendarReminderDays")
    }
    
    private func loadReminderDays() {
        reminderDaysBefore = UserDefaults.standard.integer(forKey: "calendarReminderDays")
        if reminderDaysBefore == 0 {
            reminderDaysBefore = 3 // Default to 3 days
        }
    }
}

enum CalendarError: LocalizedError {
    case notAuthorized
    case saveFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized. Please enable calendar access in Settings."
        case .saveFailed(let error):
            return "Failed to save calendar event: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete calendar event: \(error.localizedDescription)"
        }
    }
}

