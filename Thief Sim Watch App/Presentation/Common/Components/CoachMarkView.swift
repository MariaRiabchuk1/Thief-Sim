import SwiftUI

/// A tap-to-dismiss overlay providing instructions for a minigame.
struct CoachMarkView: View {
    let icon: String
    let instruction: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.yellow)
                
                Text(instruction)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                
                Text("Tap to dismiss")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                onDismiss()
            }
        }
    }
}
