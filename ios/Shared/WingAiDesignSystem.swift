import SwiftUI

public struct WingAiPalette: Sendable {
    public let bgCanvas: Color
    public let surface0: Color
    public let surface1: Color
    public let surface2: Color
    public let surface3: Color
    public let borderSubtle: Color
    public let borderStrong: Color
    public let borderAccent: Color
    public let accentPrimary: Color
    public let accentPrimaryContainer: Color
    public let onAccentPrimary: Color
    public let accentEmerald: Color
    public let accentEmeraldContainer: Color
    public let accentRose: Color
    public let accentRoseContainer: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textMuted: Color

    public static let dark = WingAiPalette(
        bgCanvas: Color(red: 0x16 / 255.0, green: 0x18 / 255.0, blue: 0x1D / 255.0),
        surface0: Color(red: 0x1A / 255.0, green: 0x1D / 255.0, blue: 0x24 / 255.0),
        surface1: Color(red: 0x24 / 255.0, green: 0x27 / 255.0, blue: 0x30 / 255.0),
        surface2: Color(red: 0x1C / 255.0, green: 0x1F / 255.0, blue: 0x27 / 255.0),
        surface3: Color(red: 0x2C / 255.0, green: 0x30 / 255.0, blue: 0x3B / 255.0),
        borderSubtle: Color(red: 0x2E / 255.0, green: 0x32 / 255.0, blue: 0x3E / 255.0),
        borderStrong: Color(red: 0x3B / 255.0, green: 0x40 / 255.0, blue: 0x4F / 255.0),
        borderAccent: Color(red: 0x4A / 255.0, green: 0x6C / 255.0, blue: 0xF7 / 255.0),
        accentPrimary: Color(red: 0x4A / 255.0, green: 0x6C / 255.0, blue: 0xF7 / 255.0),
        accentPrimaryContainer: Color(red: 0x1E / 255.0, green: 0x26 / 255.0, blue: 0x42 / 255.0),
        onAccentPrimary: .white,
        accentEmerald: Color(red: 0x10 / 255.0, green: 0xB9 / 255.0, blue: 0x81 / 255.0),
        accentEmeraldContainer: Color(red: 0x10 / 255.0, green: 0x2B / 255.0, blue: 0x23 / 255.0),
        accentRose: Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0),
        accentRoseContainer: Color(red: 0x2D / 255.0, green: 0x16 / 255.0, blue: 0x19 / 255.0),
        textPrimary: Color(red: 0xF3 / 255.0, green: 0xF4 / 255.0, blue: 0xF6 / 255.0),
        textSecondary: Color(red: 0x9C / 255.0, green: 0xA3 / 255.0, blue: 0xAF / 255.0),
        textMuted: Color(red: 0x6B / 255.0, green: 0x72 / 255.0, blue: 0x80 / 255.0)
    )

    public static let light = WingAiPalette(
        bgCanvas: Color(red: 0xEC / 255.0, green: 0xEE / 255.0, blue: 0xF2 / 255.0),
        surface0: Color(red: 0xE5 / 255.0, green: 0xE8 / 255.0, blue: 0xEE / 255.0),
        surface1: .white,
        surface2: Color(red: 0xDC / 255.0, green: 0xE0 / 255.0, blue: 0xE8 / 255.0),
        surface3: Color(red: 0xD1 / 255.0, green: 0xD5 / 255.0, blue: 0xDE / 255.0),
        borderSubtle: Color(red: 0xD5 / 255.0, green: 0xD9 / 255.0, blue: 0xE2 / 255.0),
        borderStrong: Color(red: 0xC4 / 255.0, green: 0xC9 / 255.0, blue: 0xD4 / 255.0),
        borderAccent: Color(red: 0x3B / 255.0, green: 0x5B / 255.0, blue: 0xDB / 255.0),
        accentPrimary: Color(red: 0x3B / 255.0, green: 0x5B / 255.0, blue: 0xDB / 255.0),
        accentPrimaryContainer: Color(red: 0xE0 / 255.0, green: 0xE7 / 255.0, blue: 0xFF / 255.0),
        onAccentPrimary: .white,
        accentEmerald: Color(red: 0x05 / 255.0, green: 0x96 / 255.0, blue: 0x69 / 255.0),
        accentEmeraldContainer: Color(red: 0xD1 / 255.0, green: 0xFA / 255.0, blue: 0xE5 / 255.0),
        accentRose: Color(red: 0xDC / 255.0, green: 0x26 / 255.0, blue: 0x26 / 255.0),
        accentRoseContainer: Color(red: 0xFE / 255.0, green: 0xE2 / 255.0, blue: 0xE2 / 255.0),
        textPrimary: Color(red: 0x16 / 255.0, green: 0x18 / 255.0, blue: 0x1D / 255.0),
        textSecondary: Color(red: 0x4B / 255.0, green: 0x55 / 255.0, blue: 0x63 / 255.0),
        textMuted: Color(red: 0x6B / 255.0, green: 0x72 / 255.0, blue: 0x80 / 255.0)
    )

    public static func forScheme(_ scheme: ColorScheme) -> WingAiPalette {
        scheme == .dark ? .dark : .light
    }
}

/// Animated shimmer skeleton bar matching Android's `WingAiSkeletonBox`.
public struct WingAiSkeletonBox: View {
    public var height: CGFloat = 14
    public var cornerRadius: CGFloat = 6

    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = -0.6

    public init(height: CGFloat = 14, cornerRadius: CGFloat = 6) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        GeometryReader { geo in
            let width = max(geo.size.width, 60)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(palette.surface2)
                .overlay(
                    LinearGradient(
                        colors: [
                            palette.surface2,
                            palette.surface3.opacity(0.95),
                            palette.surface2
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.65)
                    .offset(x: phase * width)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                phase = 1.2
            }
        }
    }
}

public struct WingAiSurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let borderColor: Color?
    private let content: Content

    public init(
        borderColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.content = content()
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor ?? palette.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

public struct CompactPillButton: View {
    @Environment(\.colorScheme) private var colorScheme
    public let title: String
    public var isPrimary: Bool = false
    public var isDisabled: Bool = false
    public let action: () -> Void

    public init(
        title: String,
        isPrimary: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isPrimary ? palette.onAccentPrimary : palette.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(isPrimary ? palette.accentPrimary : palette.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPrimary ? palette.accentPrimary : palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

/// Google Lens / Circle-to-Search style interactive region cropper with rounded white L-brackets.
public struct SelectAndSearchCropView: View {
    public let onCancel: () -> Void
    public let onConfirmCrop: (_ normalizedRect: CGRect) -> Void

    @State private var cropRect = CGRect(x: 0.06, y: 0.18, width: 0.88, height: 0.56)

    public init(
        onCancel: @escaping () -> Void,
        onConfirmCrop: @escaping (_ normalizedRect: CGRect) -> Void
    ) {
        self.onCancel = onCancel
        self.onConfirmCrop = onConfirmCrop
    }

    public var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let boxFrame = CGRect(
                x: cropRect.minX * w,
                y: cropRect.minY * h,
                width: cropRect.width * w,
                height: cropRect.height * h
            )

            ZStack {
                // Dimmed scrim outside the selection box
                Canvas { context, size in
                    var fullPath = Path(CGRect(origin: .zero, size: size))
                    let holePath = Path(roundedRect: boxFrame, cornerRadius: 16)
                    fullPath.addPath(holePath)
                    context.fill(
                        fullPath,
                        with: .color(Color.black.opacity(0.60)),
                        style: FillStyle(eoFill: true)
                    )

                    // Subtle inner border
                    context.stroke(
                        holePath,
                        with: .color(Color.white.opacity(0.32)),
                        lineWidth: 1.2
                    )

                    // 4 Rounded Google Lens L-shaped corner brackets
                    let arm: CGFloat = min(24, boxFrame.width * 0.25, boxFrame.height * 0.25)
                    var brackets = Path()
                    // Top-Left
                    brackets.move(to: CGPoint(x: boxFrame.minX, y: boxFrame.minY + arm))
                    brackets.addLine(to: CGPoint(x: boxFrame.minX, y: boxFrame.minY))
                    brackets.addLine(to: CGPoint(x: boxFrame.minX + arm, y: boxFrame.minY))
                    // Top-Right
                    brackets.move(to: CGPoint(x: boxFrame.maxX - arm, y: boxFrame.minY))
                    brackets.addLine(to: CGPoint(x: boxFrame.maxX, y: boxFrame.minY))
                    brackets.addLine(to: CGPoint(x: boxFrame.maxX, y: boxFrame.minY + arm))
                    // Bottom-Left
                    brackets.move(to: CGPoint(x: boxFrame.minX, y: boxFrame.maxY - arm))
                    brackets.addLine(to: CGPoint(x: boxFrame.minX, y: boxFrame.maxY))
                    brackets.addLine(to: CGPoint(x: boxFrame.minX + arm, y: boxFrame.maxY))
                    // Bottom-Right
                    brackets.move(to: CGPoint(x: boxFrame.maxX - arm, y: boxFrame.maxY))
                    brackets.addLine(to: CGPoint(x: boxFrame.maxX, y: boxFrame.maxY))
                    brackets.addLine(to: CGPoint(x: boxFrame.maxX, y: boxFrame.maxY - arm))

                    context.stroke(
                        brackets,
                        with: .color(.white),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                }
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            let startX = min(max(value.startLocation.x / w, 0.02), 0.98)
                            let startY = min(max(value.startLocation.y / h, 0.04), 0.85)
                            let curX = min(max(value.location.x / w, 0.02), 0.98)
                            let curY = min(max(value.location.y / h, 0.04), 0.85)
                            let minX = min(startX, curX)
                            let minY = min(startY, curY)
                            let maxW = max(abs(curX - startX), 0.18)
                            let maxH = max(abs(curY - startY), 0.16)
                            cropRect = CGRect(
                                x: min(minX, 0.98 - maxW),
                                y: min(minY, 0.86 - maxH),
                                width: maxW,
                                height: maxH
                            )
                        }
                )

                // Bottom floating Cancel + Analyze dock
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color(red: 0x24 / 255.0, green: 0x27 / 255.0, blue: 0x30 / 255.0))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            onConfirmCrop(cropRect)
                        } label: {
                            Text("Analyze")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color(red: 0x4A / 255.0, green: 0x6C / 255.0, blue: 0xF7 / 255.0))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .background(Color(red: 0x16 / 255.0, green: 0x18 / 255.0, blue: 0x1D / 255.0).opacity(0.95))
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}
