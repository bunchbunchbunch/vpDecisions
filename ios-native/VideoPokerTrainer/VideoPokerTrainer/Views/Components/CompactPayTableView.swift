import SwiftUI

struct CompactPayTableView: View {
    let paytable: PayTable

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(paytable.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text("5 coins")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "667eea").opacity(0.1))

            // Rows in 2 columns
            HStack(spacing: 4) {
                let midpoint = (paytable.rows.count + 1) / 2

                // Left column (top half of hands)
                VStack(spacing: 1) {
                    ForEach(Array(paytable.rows.enumerated()), id: \.element.id) { index, row in
                        if index < midpoint {
                            rowView(row: row, index: index)
                        }
                    }
                }

                // Right column (bottom half of hands)
                VStack(spacing: 1) {
                    ForEach(Array(paytable.rows.enumerated()), id: \.element.id) { index, row in
                        if index >= midpoint {
                            rowView(row: row, index: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }

    private func rowView(row: PayTableRow, index: Int) -> some View {
        HStack(spacing: 4) {
            Text(row.handName)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(row.payouts[4])")
                .font(.caption2)
                .fontWeight(.semibold)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(index % 2 == 0 ? Color(.systemGray6) : Color.clear)
        .cornerRadius(4)
    }
}

#Preview {
    CompactPayTableView(paytable: .jacksOrBetter96)
        .padding()
}
