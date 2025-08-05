import SwiftUI

// MARK: - Протоколы (оставлены как есть)
protocol ProgressDisplayable {
    var progressPercentage: Int { get }
}

protocol BackgroundProviding {
    associatedtype BackgroundContent: View
    func makeBackground() -> BackgroundContent
}

// MARK: - Лоадинг: музыкальная волна
struct BassSplashLoadingOverlay<Background: View>: View, ProgressDisplayable {
    let progress: Double
    let backgroundView: Background
    
    var progressPercentage: Int { Int(progress * 100) }
    
    init(progress: Double, @ViewBuilder background: () -> Background) {
        self.progress = progress
        self.backgroundView = background()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundView
                content(in: geo)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    private func content(in geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        return Group {
            if isLandscape {
                horizontalLayout(in: geometry)
            } else {
                verticalLayout(in: geometry)
            }
        }
    }
    
    private func verticalLayout(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Пульсирующий логотип "BASS"
            ZStack {
                Circle()
                    .fill(Color(hex: "FF0066")) // неоновый розовый
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + progress / 5)
                    .animation(.easeInOut(duration: 0.4), value: progress)
                
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    .frame(width: 110, height: 110)
                    .blur(radius: 4)
                
                Text("BASS")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "FF0066").opacity(0.7), radius: 8)
            }
            .rotationEffect(.degrees(progress * 360)) // лёгкое вращение
            
            progressSection(width: geometry.size.width * 0.7)
            
            Text("SPLASH")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .kerning(2)
                .shadow(radius: 6)
                .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private func horizontalLayout(in geometry: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF0066"))
                        .frame(width: 70, height: 70)
                        .scaleEffect(1 + progress / 6)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                    
                    Text("BASS")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                }
                
                progressSection(width: geometry.size.width * 0.3)
            }
            
            VStack(spacing: 16) {
                Text("SPLASH")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width * 0.35)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func progressSection(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text("Loading \(progressPercentage)%")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .shadow(radius: 1)
            
            BassSplashProgressBar(value: progress)
                .frame(width: width, height: 10)
        }
        .padding(16)
        .background(Color.black.opacity(0.25))
        .cornerRadius(16)
        .padding(.bottom, 20)
    }
}

// MARK: - Фон: тёмный с неоновым градиентом
extension BassSplashLoadingOverlay where Background == BassSplashBackground {
    init(progress: Double) {
        self.init(progress: progress) { BassSplashBackground() }
    }
}

struct BassSplashBackground: View, BackgroundProviding {
    func makeBackground() -> some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "0A001F"), // тёмно-фиолетовый
                Color(hex: "120033"),
                Color(hex: "0A001F")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        makeBackground()
    }
}

// MARK: - Прогресс-бар: звуковая волна
struct BassSplashProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фон
                Capsule()
                    .fill(Color.white.opacity(0.15))
                
                // Прогресс — как бас-волна
                WaveProgress(width: geometry.size.width, progress: value)
                    .mask(
                        Capsule()
                            .frame(width: CGFloat(value) * geometry.size.width, height: geometry.size.height)
                            .animation(.easeInOut(duration: 0.3), value: value)
                    )
            }
        }
        .cornerRadius(5)
    }
}

// Внутренняя структура: анимированная волна
struct WaveProgress: View {
    let width: CGFloat
    let progress: Double
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF0066"), // розовый
                    Color(hex: "990033"), // глубокий
                    Color(hex: "FF0066")
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .mask(
                WaveMask(width: width, offset: offset)
            )
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                offset = 1
            }
        }
    }
}

struct WaveMask: View {
    let width: CGFloat
    let offset: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let waveHeight: CGFloat = h * 0.8
            let waveWidth: CGFloat = w / 5
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: h))
                
                for i in 0...Int(w / waveWidth) {
                    let x = CGFloat(i) * waveWidth - (offset * w * 2)
                    let y = h - waveHeight * sin(CGFloat(i) * .pi + offset * .pi * 2)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.closeSubpath()
            }
        }
    }
}

// MARK: - Превью
#Preview("Vertical") {
    BassSplashLoadingOverlay(progress: 0.4)
}

#Preview("Horizontal") {
    BassSplashLoadingOverlay(progress: 0.4)
        .previewInterfaceOrientation(.landscapeRight)
}
