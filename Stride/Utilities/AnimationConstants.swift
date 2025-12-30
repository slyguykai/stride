import SwiftUI

/// Centralized animation constants for consistent motion across the app
/// All animations should reference these values to maintain 60fps and visual harmony
///
/// ## Phase 8 Animation Audit
/// | Context | Animation | FPS Target |
/// |---------|-----------|------------|
/// | Card transitions | `.strideSpring` | 60fps |
/// | Card reordering | `.strideSpringResponsive` | 60fps |
/// | Modal/sheet | `.strideSpringGentle` | 60fps |
/// | Micro-interactions | `.strideQuick` | 60fps |
/// | Loading/shimmer | Linear 1.5s | 60fps |
enum AnimationConstants {
    
    // MARK: - Spring Parameters
    
    /// Standard spring for most card and view transitions
    /// Response: 0.4s, Damping: 0.8 - Smooth, not bouncy
    static let springResponse: Double = 0.4
    static let springDamping: Double = 0.8
    
    /// Quick spring for micro-interactions (toggles, buttons)
    /// Response: 0.25s, Damping: 0.9 - Snappy, minimal overshoot
    static let quickSpringResponse: Double = 0.25
    static let quickSpringDamping: Double = 0.9
    
    /// Gentle spring for modals and large view changes
    /// Response: 0.5s, Damping: 0.85 - Smooth, elegant
    static let gentleSpringResponse: Double = 0.5
    static let gentleSpringDamping: Double = 0.85
    
    /// Responsive spring for gesture-driven animations
    /// Response: 0.3s, Damping: 0.8 - Tracks finger closely
    static let responsiveSpringResponse: Double = 0.3
    static let responsiveSpringDamping: Double = 0.8
    
    /// Bouncy spring for celebration/success states
    /// Response: 0.5s, Damping: 0.6 - Playful bounce
    static let bouncySpringResponse: Double = 0.5
    static let bouncySpringDamping: Double = 0.6
    
    // MARK: - Duration Constants
    
    /// Fast duration for micro-interactions
    static let durationFast: Double = 0.15
    
    /// Standard duration for most transitions
    static let durationStandard: Double = 0.3
    
    /// Slow duration for emphasis or complex animations
    static let durationSlow: Double = 0.5
    
    /// Stagger delay between items in a list
    static let staggerDelay: Double = 0.05
}

// MARK: - SwiftUI Animation Extensions

extension Animation {
    
    /// Standard spring animation for Stride
    /// Use for card transitions, list changes, most UI updates
    static var strideSpring: Animation {
        .spring(
            response: AnimationConstants.springResponse,
            dampingFraction: AnimationConstants.springDamping
        )
    }
    
    /// Quick spring for micro-interactions
    /// Use for toggles, checkmarks, small state changes
    static var strideQuick: Animation {
        .spring(
            response: AnimationConstants.quickSpringResponse,
            dampingFraction: AnimationConstants.quickSpringDamping
        )
    }
    
    /// Gentle spring for modals and overlays
    /// Use for sheet presentations, large view changes
    static var strideSpringGentle: Animation {
        .spring(
            response: AnimationConstants.gentleSpringResponse,
            dampingFraction: AnimationConstants.gentleSpringDamping
        )
    }
    
    /// Responsive spring for gesture-following
    /// Use for drag gestures, swipe cards
    static var strideSpringResponsive: Animation {
        .spring(
            response: AnimationConstants.responsiveSpringResponse,
            dampingFraction: AnimationConstants.responsiveSpringDamping
        )
    }
    
    /// Bouncy spring for celebrations
    /// Use for completion animations, success states
    static var strideSpringBouncy: Animation {
        .spring(
            response: AnimationConstants.bouncySpringResponse,
            dampingFraction: AnimationConstants.bouncySpringDamping
        )
    }
    
    /// Staggered animation for list items
    /// - Parameter index: The item's index in the list
    /// - Returns: Animation with delay based on index
    static func strideStaggered(index: Int) -> Animation {
        strideSpring.delay(Double(index) * AnimationConstants.staggerDelay)
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply standard Stride spring animation
    func animateWithStrideSpring<V: Equatable>(value: V) -> some View {
        animation(.strideSpring, value: value)
    }
    
    /// Apply staggered entrance animation for list items
    func staggeredEntrance(index: Int) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .animation(
                .strideStaggered(index: index),
                value: true
            )
    }
}

