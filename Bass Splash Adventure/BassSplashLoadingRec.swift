import SwiftUI
import Combine
import WebKit

// MARK: - Протоколы

/// Протокол для управления состоянием веб-загрузки
protocol WebLoadable: AnyObject {
    var state: BassSplashWebStatus { get set }
    func setConnectivity(_ available: Bool)
}

/// Протокол для мониторинга прогресса загрузки
protocol ProgressMonitoring {
    func observeProgression()
    func monitor(_ webView: WKWebView)
}

// MARK: - Основной загрузчик веб-представления

/// Класс для управления загрузкой и состоянием веб-представления
final class BassSplashWebLoader: NSObject, ObservableObject, WebLoadable, ProgressMonitoring {
    // MARK: - Свойства
    
    @Published var state: BassSplashWebStatus = .standby
    
    let resource: URL
    private var cancellables = Set<AnyCancellable>()
    private var progressPublisher = PassthroughSubject<Double, Never>()
    private var webViewProvider: (() -> WKWebView)?
    
    // MARK: - Инициализация
    
    init(resourceURL: URL) {
        self.resource = resourceURL
        super.init()
        observeProgression()
    }
    
    // MARK: - Публичные методы
    
    /// Привязка веб-представления к загрузчику
    func attachWebView(factory: @escaping () -> WKWebView) {
        webViewProvider = factory
        triggerLoad()
    }
    
    /// Установка доступности подключения
    func setConnectivity(_ available: Bool) {
        switch (available, state) {
        case (true, .noConnection):
            triggerLoad()
        case (false, _):
            state = .noConnection
        default:
            break
        }
    }
    
    // MARK: - Приватные методы загрузки
    
    /// Запуск загрузки веб-представления
    private func triggerLoad() {
        guard let webView = webViewProvider?() else { return }
        
        let request = URLRequest(url: resource, timeoutInterval: 12)
        state = .progressing(progress: 0)
        
        webView.navigationDelegate = self
        webView.load(request)
        monitor(webView)
    }
    
    // MARK: - Методы мониторинга
    
    /// Наблюдение за прогрессом загрузки
    func observeProgression() {
        progressPublisher
            .removeDuplicates()
            .sink { [weak self] progress in
                guard let self else { return }
                self.state = progress < 1.0 ? .progressing(progress: progress) : .finished
            }
            .store(in: &cancellables)
    }
    
    /// Мониторинг прогресса веб-представления
    func monitor(_ webView: WKWebView) {
        webView.publisher(for: \.estimatedProgress)
            .sink { [weak self] progress in
                self?.progressPublisher.send(progress)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Расширение для обработки навигации

extension BassSplashWebLoader: WKNavigationDelegate {
    /// Обработка ошибок при навигации
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    /// Обработка ошибок при provisional навигации
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    // MARK: - Приватные методы обработки ошибок
    
    /// Обобщенный метод обработки ошибок навигации
    private func handleNavigationError(_ error: Error) {
        state = .failure(reason: error.localizedDescription)
    }
}

// MARK: - Расширения для улучшения функциональности

extension BassSplashWebLoader {
    /// Создание загрузчика с безопасным URL
    convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(resourceURL: url)
    }
}
