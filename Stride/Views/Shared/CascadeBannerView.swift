import SwiftUI

struct CascadeBannerView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.green)
            Text("Completing this unblocked \(count) more tasks.")
                .font(.subheadline)
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
