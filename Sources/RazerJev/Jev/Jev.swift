import Foundation

struct ChoiceAnswer {
    let choice: String
    let probabilities: [String: Double]
    let seconds: Double
}

enum JevError: Error, CustomStringConvertible {
    case noAPIKey
    case http(status: Int, body: String)
    case unexpectedAnswer(String)
    var description: String {
        switch self {
        case .noAPIKey:
            return "No TypeSafe key. Set TYPESAFE_API_KEY, or store it with: security add-generic-password -s \(APIKey.keychainService) -a \(APIKey.keychainAccount) -w"
        case .http(let status, let body): return "Jev returned \(status): \(body.prefix(200))"
        case .unexpectedAnswer(let body): return "Jev's answer had no choice: \(body.prefix(200))"
        }
    }
}

struct Jev {
    let apiKey: String
    static let endpoint = URL(string: "https://api.typesafe.ai/v1/systemone")!

    func choose(instructions: String, criteria: [String: String], screen png: Data) async throws -> ChoiceAnswer {
        let reference = "pointer-screen-5c1e"
        let request: [String: Any] = [
            "model": "jev-latest",
            "state": ["screen": reference],
            "assets": [reference: ["type": "image", "part": "screen"]],
            "questions": ["answer": ["type": "choice", "instructions": instructions, "criteria": criteria]],
        ]

        let boundary = "razer-helper-\(UUID().uuidString)"
        var body = Data()
        func part(_ name: String, filename: String? = nil, type: String, _ data: Data) {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"".data(using: .utf8)!)
            if let filename { body.append("; filename=\"\(filename)\"".data(using: .utf8)!) }
            body.append("\r\nContent-Type: \(type)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        part("request", type: "application/json", try JSONSerialization.data(withJSONObject: request))
        part("screen", filename: "screen.png", type: "image/png", png)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var http = URLRequest(url: Self.endpoint)
        http.httpMethod = "POST"
        http.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        http.setValue("true", forHTTPHeaderField: "TypeSafe-Danger-Zone-Images")
        http.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        http.timeoutInterval = 10

        let started = Date()
        let (data, response) = try await URLSession.shared.upload(for: http, from: body)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let text = String(decoding: data, as: UTF8.self)
        guard status == 200 else { throw JevError.http(status: status, body: text) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let answers = json["answers"] as? [String: Any],
              let answer = answers["answer"] as? [String: Any],
              let choice = answer["choice"] as? String,
              let probabilities = answer["probabilities"] as? [String: Double]
        else { throw JevError.unexpectedAnswer(text) }
        return ChoiceAnswer(choice: choice, probabilities: probabilities, seconds: Date().timeIntervalSince(started))
    }
}
