import XCTest
@testable import acal

final class TimesTests: XCTestCase {
    func testParsesATimeWithAnOffset() {
        let parsed = parseTime("2026-11-03T15:00:00+08:00", option: "--start")
        XCTAssertFalse(parsed.dateOnly)
        XCTAssertEqual(parsed.date.timeIntervalSince1970, 1_793_689_200)
    }

    func testParsesZuluTime() {
        let parsed = parseTime("2026-11-03T07:00:00Z", option: "--start")
        XCTAssertEqual(parsed.date.timeIntervalSince1970, 1_793_689_200)
    }

    func testReadsATimeWithoutAnOffsetInTheSystemTimeZone() {
        let parsed = parseTime("2026-11-03T15:30", option: "--start")
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: parsed.date)
        XCTAssertEqual([parts.year, parts.month, parts.day, parts.hour, parts.minute], [2026, 11, 3, 15, 30])
    }

    func testABareDateIsDateOnlyAndStartsAtMidnight() {
        let parsed = parseTime("2026-11-03", option: "--from")
        XCTAssertTrue(parsed.dateOnly)
        XCTAssertEqual(Calendar.current.component(.hour, from: parsed.date), 0)
    }

    func testAnUpperBoundOnADateIsTheNextMidnight() {
        let parsed = parseTime("2026-11-03", option: "--to")
        let lower = rangeBound(parsed, upper: false)
        let upper = rangeBound(parsed, upper: true)
        XCTAssertEqual(Calendar.current.dateComponents([.day], from: lower, to: upper).day, 1)
    }

    func testAnUpperBoundOnATimeIsLeftAlone() {
        let parsed = parseTime("2026-11-03T15:00:00+08:00", option: "--to")
        XCTAssertEqual(rangeBound(parsed, upper: true), parsed.date)
    }

    func testOutputRoundTripsAndCarriesAnOffset() {
        let original = parseTime("2026-11-03T15:00:00+08:00", option: "--start").date
        let text = formatTime(original)
        XCTAssertNotNil(text.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]\d{2}:\d{2}|Z)$"#, options: .regularExpression))
        XCTAssertEqual(parseTime(text, option: "--start").date, original)
    }

    func testReadsDurations() {
        XCTAssertEqual(parseOffset("30m", option: "--alarm"), 1800)
        XCTAssertEqual(parseOffset("2h", option: "--alarm"), 7200)
        XCTAssertEqual(parseOffset("1d", option: "--alarm"), 86400)
    }

    func testFormatsDurationsInTheLargestWholeUnit() {
        XCTAssertEqual(formatOffset(1800), "30m")
        XCTAssertEqual(formatOffset(7200), "2h")
        XCTAssertEqual(formatOffset(86400), "1d")
        XCTAssertEqual(formatOffset(5400), "90m")
    }

    func testAnAlarmAfterTheStartKeepsItsSign() {
        XCTAssertEqual(formatOffset(-32400), "-9h")
        XCTAssertEqual(formatOffset(0), "0m")
    }
}
