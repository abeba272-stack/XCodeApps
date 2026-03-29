import Foundation

struct AnthropicClient: AIClient, @unchecked Sendable {
    static let defaultModel = "claude-3-5-haiku-latest"
    static let apiVersion = "2023-06-01"

    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession
    private let maxTokens: Int

    init(
        apiKey: String,
        model: String = AnthropicClient.defaultModel,
        endpoint: URL = AnthropicClient.defaultEndpoint,
        maxTokens: Int = 1024,
        session: URLSession? = nil
    ) {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = trimmedModel.isEmpty ? Self.defaultModel : trimmedModel
        self.endpoint = endpoint
        self.maxTokens = max(maxTokens, 1)
        self.session = session ?? Self.makeSession()
    }

    func send(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AppError.settings("Add an Anthropic API key before using the Anthropic provider.")
        }

        let body: Data
        do {
            body = try JSONEncoder().encode(
                MessagesRequest(
                    model: model,
                    maxTokens: maxTokens,
                    messages: [
                        .init(role: "user", content: prompt)
                    ]
                )
            )
        } catch {
            throw AppError.ai("The Anthropic request could not be prepared.")
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.ai("Anthropic returned an invalid response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw makeAPIError(from: data, statusCode: httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                throw AppError.ai("Anthropic returned an empty response.")
            }

            let decoded: MessagesResponse
            do {
                decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
            } catch {
                throw AppError.ai("Anthropic returned a response that could not be decoded.")
            }

            let content = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else {
                throw AppError.ai("Anthropic returned an empty completion.")
            }

            return content
        } catch let appError as AppError {
            throw appError
        } catch let urlError as URLError {
            throw mapTransportError(urlError)
        } catch {
            throw AppError.ai(error.localizedDescription.isEmpty ? "The Anthropic request failed." : error.localizedDescription)
        }
    }
}

private extension AnthropicClient {
    static var defaultEndpoint: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.anthropic.com"
        components.path = "/v1/messages"

        guard let url = components.url else {
            preconditionFailure("Failed to construct the default Anthropic endpoint.")
        }

        return url
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func makeAPIError(from data: Data, statusCode: Int) -> AppError {
        if let apiError = try? JSONDecoder().decode(MessagesAPIErrorEnvelope.self, from: data) {
            return .ai(apiError.error.message)
        }

        return .ai("Anthropic returned HTTP \(statusCode).")
    }

    func mapTransportError(_ error: URLError) -> AppError {
        switch error.code {
        case .timedOut:
            return .ai("Anthropic took too long to respond.")
        case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost:
            return .ai("Anthropic could not be reached.")
        default:
            return .ai(error.localizedDescription.isEmpty ? "The Anthropic request failed." : error.localizedDescription)
        }
    }
}

private struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct MessagesResponse: Decodable {
    let content: [ContentBlock]

    var text: String {
        content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
    }

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

private struct MessagesAPIErrorEnvelope: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
