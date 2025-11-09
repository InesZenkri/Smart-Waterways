import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}
