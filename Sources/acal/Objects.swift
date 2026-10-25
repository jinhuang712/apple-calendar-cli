import AppKit
import EventKit

private func typeName(_ type: EKCalendarType) -> String {
    switch type {
    case .local: "local"
    case .calDAV: "calDAV"
    case .exchange: "exchange"
    case .subscription: "subscription"
    case .birthday: "birthday"
    @unknown default: "unknown"
    }
}

private func hexColor(_ color: CGColor?) -> String? {
    guard let color, let rgb = NSColor(cgColor: color)?.usingColorSpace(.sRGB) else { return nil }
    let parts = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent].map { Int(($0 * 255).rounded()) }
    return String(format: "#%02X%02X%02X", parts[0], parts[1], parts[2])
}

func calendarObject(_ calendar: EKCalendar) -> [String: Any] {
    var object: [String: Any] = [
        "id": calendar.calendarIdentifier,
        "title": calendar.title,
        "account": calendar.source.title,
        "type": typeName(calendar.type),
        "readOnly": !calendar.allowsContentModifications
    ]
    if let color = hexColor(calendar.cgColor) { object["color"] = color }
    return object
}

private func frequencyName(_ frequency: EKRecurrenceFrequency) -> String {
    switch frequency {
    case .daily: "daily"
    case .weekly: "weekly"
    case .monthly: "monthly"
    case .yearly: "yearly"
    @unknown default: "unknown"
    }
}

private func ruleObject(_ rule: EKRecurrenceRule) -> [String: Any] {
    var object: [String: Any] = ["frequency": frequencyName(rule.frequency), "interval": rule.interval]
    if let end = rule.recurrenceEnd {
        if end.occurrenceCount > 0 { object["count"] = end.occurrenceCount }
        if let date = end.endDate { object["until"] = formatTime(date) }
    }
    return object
}

private func alarmText(_ alarm: EKAlarm) -> String {
    if let date = alarm.absoluteDate { return formatTime(date) }
    return formatOffset(-alarm.relativeOffset)
}

private func statusName(_ status: EKParticipantStatus) -> String {
    switch status {
    case .accepted: "accepted"
    case .declined: "declined"
    case .tentative: "tentative"
    case .pending: "pending"
    case .delegated: "delegated"
    case .completed: "completed"
    case .inProcess: "inProcess"
    default: "unknown"
    }
}

private func attendeeObject(_ attendee: EKParticipant) -> [String: Any] {
    var object: [String: Any] = ["status": statusName(attendee.participantStatus)]
    if let name = attendee.name { object["name"] = name }
    if attendee.url.scheme == "mailto" { object["email"] = attendee.url.absoluteString.replacingOccurrences(of: "mailto:", with: "") }
    return object
}

/// The fields of F3, plus the fields of F4 when `detailed`.
func eventObject(_ event: EKEvent, detailed: Bool = false) -> [String: Any] {
    var object: [String: Any] = [
        "id": event.eventIdentifier ?? "",
        "title": event.title ?? "",
        "start": formatTime(event.startDate),
        "end": formatTime(event.endDate),
        "allDay": event.isAllDay,
        "calendar": event.calendar.title,
        "recurring": event.hasRecurrenceRules
    ]
    if let location = event.location, !location.isEmpty { object["location"] = location }
    guard detailed else { return object }
    if let notes = event.notes, !notes.isEmpty { object["notes"] = notes }
    if let url = event.url { object["url"] = url.absoluteString }
    object["alarms"] = (event.alarms ?? []).map(alarmText)
    if let rule = event.recurrenceRules?.first { object["recurrenceRule"] = ruleObject(rule) }
    object["attendees"] = (event.attendees ?? []).map(attendeeObject)
    return object
}
