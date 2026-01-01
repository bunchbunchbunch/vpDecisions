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

            // Rows
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(Array(paytable.rows.enumerated()), id: \.element.id) { index, row in
                        HStack {
                            Text(row.handName)
                                .font(.footnote)
                                .frame(width: 130, alignment: .leading)

                            Spacer()

                            Text("\(row.payouts[4])")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(index % 2 == 0 ?
                                    Color(.systemGray6) : Color.clear)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

#Preview {
    CompactPayTableView(paytable: .jacksOrBetter)
        .padding()
}
