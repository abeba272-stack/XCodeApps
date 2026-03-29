import Foundation

struct OpenAIClient: AIClient, @unchecked Sendable {
    static let defaultModel = "gpt-4o-mini"

    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession

    init(
        apiKey: String,
        model: String = OpenAIClient.defaultModel,
        endpoint: URL = OpenAIClient.defaultEndpoint,
        session: URLSession? = nil
    ) {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = trimmedModel.isEmpty ? Self.defaultModel : trimmedModel
        self.endpoint = endpoint
        self.session = session ?? Self.makeSession()
    }

    func send(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AppError.settings("Add an OpenAI API key before using the OpenAI provider.")
        }

        let body: Data
        do {
            body = try JSONEncoder().encode(
                ChatCompletionsRequest(
                    model: model,
                    messages: [
                        .init(role: "user", content: prompt)
                    ]
                )
            )
        } catch {
            throw AppError.ai("The OpenAI request could not be prepared.")
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.ai("OpenAI returned an invalid response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw makeAPIError(from: data, statusCode: httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                throw AppError.ai("OpenAI returned an empty response.")
            }

            let decoded: ChatCompletionsResponse
            do {
                decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
            } catch {
                throw AppError.ai("OpenAI returned a response that could not be decoded.")
            }

            let content = decoded.firstText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else {
                throw AppError.ai("OpenAI returned an empty completion.")
            }

            return content
        } catch let appError as AppError {
            throw appError
        } catch let urlError as URLError {
            throw mapTransportError(urlError)
        } catch {
            throw AppError.ai(error.localizedDescription.isEmpty ? "The OpenAI request failed." : error.localizedDescription)
        }
    }
}

private extension OpenAIClient {
    static var defaultEndpoint: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openai.com"
        components.path = "/v1/chat/completions"

        guard let url = components.url else {
            preconditionFailure("Failed to construct the default OpenAI endpoint.")
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
        if let apiError = try? JSONDecoder().decode(ChatCompletionsAPIErrorEnvelope.self, from: data) {
            return .ai(apiError.error.message)
        }

        return .ai("OpenAI returned HTTP \(statusCode).")
    }

    func mapTransportError(_ error: URLError) -> AppError {
        switch error.code {
        case .timedOut:
            return .ai("OpenAI took too long to respond.")
        case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost:
            return .ai("OpenAI could not be reached.")
        default:
            return .ai(error.localizedDescription.isEmpty ? "The OpenAI request failed." : error.localizedDescription)
        }
    }
}

private struct ChatCompletionsRequest: Encodable {
    let model: String
    let messages: [ChatMessage]

    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatCompletionsResponse: Decodable {
    let choices: [Choice]

    var firstText: String {
        choices
            .lazy
            .map(\.message.content.textValue)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? ""
    }

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: MessageContent
    }

    enum MessageContent: Decodable {
        case text(String)
        case parts([Part])

        var textValue: String {
            switch self {
            case .text(let value):
                return value
            case .parts(let parts):
                return parts
                    .compactMap(\.text)
                    .joined(separator: "\n")
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let text = try? container.decode(String.self) {
                self = .text(text)
                return
            }

            if let parts = try? container.decode([Part].self) {
                self = .parts(parts)
                return
            }

            throw DecodingError.typeMismatch(
                MessageContent.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported OpenAI message content payload.")
            )
        }
    }

    struct Part: Decodable {
        let type: String
        let text: String?
    }
}

private struct ChatCompletionsAPIErrorEnvelope: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
