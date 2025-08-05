import SwiftUI
import Foundation

struct BassSplashEntryScreen: View {
    @StateObject private var loader: BassSplashWebLoader

    init(loader: BassSplashWebLoader) {
        _loader = StateObject(wrappedValue: loader)
    }

    var body: some View {
        ZStack {
            BassSplashWebViewBox(loader: loader)
                .opacity(loader.state == .finished ? 1 : 0.5)
            switch loader.state {
            case .progressing(let percent):
                BassSplashProgressIndicator(value: percent)
            case .failure(let err):
                BassSplashErrorIndicator(err: err) // err теперь String
            case .noConnection:
                BassSplashOfflineIndicator()
            default:
                EmptyView()
            }
        }
    }
}

private struct BassSplashProgressIndicator: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            BassSplashLoadingOverlay(progress: value)
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black)
        }
    }
}

private struct BassSplashErrorIndicator: View {
    let err: String // было Error, стало String
    var body: some View {
        Text("Ошибка: \(err)").foregroundColor(.red)
    }
}

private struct BassSplashOfflineIndicator: View {
    var body: some View {
        Text("Нет соединения").foregroundColor(.gray)
    }
}
