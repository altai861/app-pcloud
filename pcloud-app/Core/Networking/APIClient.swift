import Foundation

struct APIClient {
    let baseURL: URL
    let urlSession: URLSession

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func get<Response: Decodable>(
        path: String,
        bearerToken: String? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await performRequest(
            path: path,
            method: .get,
            bearerToken: bearerToken,
            queryItems: queryItems,
            bodyData: nil
        )
    }

    func post<Body: Encodable, Response: Decodable>(
        path: String,
        bearerToken: String? = nil,
        body: Body
    ) async throws -> Response {
        try await performRequest(
            path: path,
            method: .post,
            bearerToken: bearerToken,
            queryItems: [],
            bodyData: try encode(body)
        )
    }

    func post<Response: Decodable>(
        path: String,
        bearerToken: String? = nil
    ) async throws -> Response {
        try await performRequest(
            path: path,
            method: .post,
            bearerToken: bearerToken,
            queryItems: [],
            bodyData: nil
        )
    }

    func postMultipart<Response: Decodable>(
        path: String,
        bearerToken: String? = nil,
        parts: [MultipartFormPart]
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"

        return try await performRequest(
            path: path,
            method: .post,
            bearerToken: bearerToken,
            queryItems: [],
            bodyData: makeMultipartBody(parts: parts, boundary: boundary),
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    func put<Body: Encodable, Response: Decodable>(
        path: String,
        bearerToken: String? = nil,
        body: Body
    ) async throws -> Response {
        try await performRequest(
            path: path,
            method: .put,
            bearerToken: bearerToken,
            queryItems: [],
            bodyData: try encode(body)
        )
    }

    func delete<Response: Decodable>(
        path: String,
        bearerToken: String? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await performRequest(
            path: path,
            method: .delete,
            bearerToken: bearerToken,
            queryItems: queryItems,
            bodyData: nil
        )
    }

    private func performRequest<Response: Decodable>(
        path: String,
        method: HTTPMethod,
        bearerToken: String?,
        queryItems: [URLQueryItem],
        bodyData: Data?,
        contentType: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: method,
            bearerToken: bearerToken,
            queryItems: queryItems,
            bodyData: bodyData,
            contentType: contentType
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw APIClientError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw mapServerError(data: data, statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIClientError.decodingFailed(error)
        }
    }

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        bearerToken: String?,
        queryItems: [URLQueryItem],
        bodyData: Data?,
        contentType: String?
    ) throws -> URLRequest {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.httpBody = bodyData
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        let basePath = components?.path == "/" ? "" : (components?.path ?? "")
        components?.path = basePath + normalizedPath
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw APIClientError.invalidURL
        }

        return url
    }

    private func encode<Body: Encodable>(_ value: Body) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw APIClientError.encodingFailed(error)
        }
    }

    private func makeMultipartBody(parts: [MultipartFormPart], boundary: String) -> Data {
        var data = Data()

        for part in parts {
            data.append("--\(boundary)\r\n")
            if let filename = part.filename {
                data.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n")
                data.append("Content-Type: \(part.contentType ?? "application/octet-stream")\r\n\r\n")
            } else {
                data.append("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n")
            }
            data.append(part.data)
            data.append("\r\n")
        }

        data.append("--\(boundary)--\r\n")
        return data
    }

    private func mapServerError(data: Data, statusCode: Int) -> APIClientError {
        if
            let decoded = try? decoder.decode(APIErrorResponse.self, from: data),
            !decoded.error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return .server(message: decoded.error, statusCode: statusCode)
        }

        return .server(message: "Request failed with status code \(statusCode).", statusCode: statusCode)
    }
}

struct MultipartFormPart {
    let name: String
    let filename: String?
    let contentType: String?
    let data: Data

    static func text(name: String, value: String) -> MultipartFormPart {
        MultipartFormPart(
            name: name,
            filename: nil,
            contentType: nil,
            data: Data(value.utf8)
        )
    }

    static func file(
        name: String,
        filename: String,
        contentType: String?,
        data: Data
    ) -> MultipartFormPart {
        MultipartFormPart(
            name: name,
            filename: filename,
            contentType: contentType,
            data: data
        )
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingFailed(Error)
    case decodingFailed(Error)
    case transport(Error)
    case server(message: String, statusCode: Int)

    var isUnauthorized: Bool {
        if case let .server(_, statusCode) = self {
            return statusCode == 401
        }

        return false
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case let .encodingFailed(error):
            return "Could not encode the request: \(error.localizedDescription)"
        case let .decodingFailed(error):
            return "Could not decode the response: \(error.localizedDescription)"
        case let .transport(error):
            return "Network request failed: \(error.localizedDescription)"
        case let .server(message, _):
            return message
        }
    }
}
