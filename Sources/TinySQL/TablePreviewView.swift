import SwiftUI
import AppKit

/// Renders query results as a sortable, resizable NSTableView.
struct TablePreviewView: NSViewRepresentable {
    let columns: [String]
    let rows: [[String]]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.allowsColumnSelection = false
        tableView.columnAutoresizingStyle = .noColumnAutoresizing
        tableView.intercellSpacing = NSSize(width: 8, height: 2)
        tableView.rowHeight = 20
        tableView.headerView = NSTableHeaderView()
        tableView.gridStyleMask = [.solidVerticalGridLineMask]

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        context.coordinator.tableView = tableView
        context.coordinator.updateData(columns: columns, rows: rows)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.updateData(columns: columns, rows: rows)
    }

    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var tableView: NSTableView?
        private var headers: [String] = []
        private var dataRows: [[String]] = []
        private var sortedRows: [[String]] = []
        private var sortColumn: Int?
        private var sortAscending = true

        func updateData(columns: [String], rows: [[String]]) {
            guard let tableView else { return }

            if columns != headers {
                headers = columns
                dataRows = rows
                sortColumn = nil
                sortAscending = true

                for col in tableView.tableColumns.reversed() {
                    tableView.removeTableColumn(col)
                }

                for (i, header) in headers.enumerated() {
                    let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("col_\(i)"))
                    col.title = header
                    col.minWidth = 60
                    col.width = max(CGFloat(header.count * 9 + 20), 80)
                    col.maxWidth = 600
                    col.sortDescriptorPrototype = NSSortDescriptor(key: "\(i)", ascending: true)
                    tableView.addTableColumn(col)
                }

                sortedRows = dataRows
            } else {
                dataRows = rows
                applySorting()
            }

            tableView.reloadData()
        }

        private func applySorting() {
            if let col = sortColumn, col < headers.count {
                let sorted = dataRows.sorted { a, b in
                    let va = col < a.count ? a[col] : ""
                    let vb = col < b.count ? b[col] : ""
                    if let na = Double(va), let nb = Double(vb) {
                        return sortAscending ? na < nb : na > nb
                    }
                    return sortAscending
                        ? va.localizedCompare(vb) == .orderedAscending
                        : va.localizedCompare(vb) == .orderedDescending
                }
                sortedRows = sorted
            } else {
                sortedRows = dataRows
            }
        }

        // MARK: - DataSource

        func numberOfRows(in tableView: NSTableView) -> Int {
            sortedRows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn else { return nil }
            let id = tableColumn.identifier
            guard let colStr = id.rawValue.split(separator: "_").last,
                  let colIndex = Int(colStr),
                  row < sortedRows.count else { return nil }

            let value = colIndex < sortedRows[row].count ? sortedRows[row][colIndex] : ""

            let cellID = NSUserInterfaceItemIdentifier("cell")
            let cell: NSTextField
            if let existing = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField {
                cell = existing
            } else {
                cell = NSTextField(labelWithString: "")
                cell.identifier = cellID
                cell.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                cell.cell?.truncatesLastVisibleLine = true
            }

            cell.stringValue = value
            cell.lineBreakMode = .byTruncatingTail
            cell.maximumNumberOfLines = 1
            cell.toolTip = value

            // Dim NULL values
            cell.textColor = value == "NULL" ? .tertiaryLabelColor : .labelColor

            return cell
        }

        // MARK: - Sorting

        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let descriptor = tableView.sortDescriptors.first,
                  let key = descriptor.key,
                  let colIndex = Int(key) else { return }
            sortColumn = colIndex
            sortAscending = descriptor.ascending
            applySorting()
            tableView.reloadData()
        }
    }
}
