import Foundation

struct NetworkRequest {
    let url: URL
    var method: String = "POST"
    var headers: [String: String] = [:]
    var body: Data? = nil
}

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let backoff: Duration

    static let standard = RetryPolicy(maxAttempts: 2, backoff: .milliseconds(350))
}

protocol NetworkClient: Sendable {
    func send(_ request: NetworkRequest, retryPolicy: RetryPolicy) async throws -> Data
}

final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    private let session: URLSession
    private let logger: any AppLogger

    init(logger: any AppLogger) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
        self.logger = logger
    }

    func send(_ request: NetworkRequest, retryPolicy: RetryPolicy = .standard) async throws -> Data {
        var lastError: Error?

        for attempt in 1...max(retryPolicy.maxAttempts, 1) {
            do {
                let responseData = try await perform(request)
                if attempt > 1 {
                    logger.info("Recovered after retry \(attempt).", category: "NetworkClient")
                }
                return responseData
            } catch {
                lastError = error
                logger.error("Request attempt \(attempt) failed: \(error.localizedDescription)", category: "NetworkClient")

                guard attempt < retryPolicy.maxAttempts, shouldRetry(for: error) else {
                    throw error
                }

                try? await Task.sleep(for: retryPolicy.backoff)
            }
        }

        throw lastError ?? NetworkFailure.transport("Unknown network failure.")
    }

    private func perform(_ request: NetworkRequest) async throws -> Data {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkFailure.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkFailure.unacceptableStatusCode(httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                throw NetworkFailure.emptyResponse
            }

            return data
        } catch let error as NetworkFailure {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw NetworkFailure.timedOut
            default:
                throw NetworkFailure.transport(error.localizedDescription)
            }
        } catch {
            throw NetworkFailure.transport(error.localizedDescription)
        }
    }

    private func shouldRetry(for error: Error) -> Bool {
        switch error {
        case NetworkFailure.timedOut,
             NetworkFailure.transport:
            return true
        default:
            return false
        }
    }
}
