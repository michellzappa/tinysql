import AppKit
import TinyKit

/// Syntax highlighter for SQL files.
/// Colors keywords, comments, strings, and numbers.
final class SQLHighlighter: SyntaxHighlighting {
    var baseFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    private var isDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private var keywordColor: NSColor {
        isDark ? NSColor(red: 0.667, green: 0.867, blue: 0.267, alpha: 1.0)
               : NSColor(red: 0.4, green: 0.55, blue: 0.1, alpha: 1.0)
    }

    private var commentColor: NSColor {
        isDark ? NSColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private var stringColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
    }

    private var numberColor: NSColor {
        isDark ? NSColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)
               : NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
    }

    // Precompiled regex patterns
    private static let keywordRegex = try! NSRegularExpression(
        pattern: #"\b(SELECT|FROM|WHERE|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|JOIN|ON|INNER|LEFT|RIGHT|FULL|CROSS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|AS|DISTINCT|ALL|AND|OR|NOT|IN|EXISTS|BETWEEN|LIKE|ILIKE|IS|NULL|DEFAULT|PRIMARY|KEY|FOREIGN|REFERENCES|CONSTRAINT|INDEX|UNIQUE|TABLE|DATABASE|SCHEMA|VIEW|TRIGGER|PROCEDURE|FUNCTION|CAST|CASE|WHEN|THEN|ELSE|END|UNION|INTERSECT|EXCEPT|WITH|RECURSIVE|VALUES|SET|INTO|IF|BEGIN|COMMIT|ROLLBACK|TRANSACTION|GRANT|REVOKE|CASCADE|RESTRICT|ADD|COLUMN|RENAME|TO|TYPE|USING|RETURNS|SERIAL|BIGSERIAL|VARCHAR|INTEGER|INT|BIGINT|SMALLINT|TEXT|BOOLEAN|BOOL|TIMESTAMP|DATE|TIME|NUMERIC|DECIMAL|FLOAT|DOUBLE|PRECISION|CHAR|BYTEA|JSON|JSONB|UUID|ARRAY|ENUM|NOT NULL|CHECK|EXPLAIN|ANALYZE|TRUNCATE|REPLACE|CONFLICT|DO|NOTHING|RETURNING|ASC|DESC|NULLS|FIRST|LAST|OVER|PARTITION|ROW|ROWS|RANGE|UNBOUNDED|PRECEDING|FOLLOWING|CURRENT|WINDOW|MATERIALIZED|TEMPORARY|TEMP|UNLOGGED|SEQUENCE|OWNED|NONE|LATERAL|COALESCE|GREATEST|LEAST|COUNT|SUM|AVG|MIN|MAX|EXTRACT|EPOCH|NOW|TRUE|FALSE)\b"#,
        options: .caseInsensitive
    )
    private static let lineCommentRegex = try! NSRegularExpression(
        pattern: #"--[^\n]*"#
    )
    private static let blockCommentRegex = try! NSRegularExpression(
        pattern: #"/\*[\s\S]*?\*/"#,
        options: .dotMatchesLineSeparators
    )
    private static let stringRegex = try! NSRegularExpression(
        pattern: #"'(?:''|[^'])*'"#
    )
    private static let numberRegex = try! NSRegularExpression(
        pattern: #"\b\d+\.?\d*\b"#
    )

    func highlight(_ textStorage: NSTextStorage) {
        let source = textStorage.string
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Reset to base
        textStorage.addAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.clear,
        ], range: fullRange)

        // First pass: mark strings and comments (these take priority)
        var skipRanges: [NSRange] = []

        for match in Self.stringRegex.matches(in: source, range: fullRange) {
            skipRanges.append(match.range)
            textStorage.addAttribute(.foregroundColor, value: stringColor, range: match.range)
        }
        for match in Self.lineCommentRegex.matches(in: source, range: fullRange) {
            skipRanges.append(match.range)
            textStorage.addAttribute(.foregroundColor, value: commentColor, range: match.range)
        }
        for match in Self.blockCommentRegex.matches(in: source, range: fullRange) {
            skipRanges.append(match.range)
            textStorage.addAttribute(.foregroundColor, value: commentColor, range: match.range)
        }

        // Second pass: keywords and numbers, skipping strings/comments
        let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .semibold)

        for match in Self.keywordRegex.matches(in: source, range: fullRange) {
            guard !isInside(match.range, skipRanges) else { continue }
            textStorage.addAttributes([
                .foregroundColor: keywordColor,
                .font: boldFont,
            ], range: match.range)
        }

        for match in Self.numberRegex.matches(in: source, range: fullRange) {
            guard !isInside(match.range, skipRanges) else { continue }
            textStorage.addAttribute(.foregroundColor, value: numberColor, range: match.range)
        }

        textStorage.endEditing()
    }

    private func isInside(_ range: NSRange, _ skipRanges: [NSRange]) -> Bool {
        skipRanges.contains { skip in
            skip.location <= range.location &&
            skip.location + skip.length >= range.location + range.length
        }
    }
}
