//
//  NetworkManager.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import Foundation

protocol NetworkManagerProtocol: AnyObject {
    func fetchDigimons(page: Int, pageSize: Int, searchText: String?, completion: @escaping (Result<DigimonResponse, Error>) -> Void)
    func fetchDigimonDetail(id: Int, completion: @escaping (Result<DigimonDetail, Error>) -> Void)
}

class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    private let baseURL = "https://digi-api.com/api/v1"
    
    private init() {}
    
    func fetchDigimons(page: Int = 0, pageSize: Int = 8, searchText: String? = nil, completion: @escaping (Result<DigimonResponse, Error>) -> Void) {
        var urlString = "\(baseURL)/digimon?page=\(page)&pageSize=\(pageSize)"
        
        if let text = searchText, !text.isEmpty {
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            urlString += "&name=\(encodedText)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        performRequest(url: url) { (result: Result<DigimonResponse, Error>) in
            switch result {
            case .success(let response):
                if searchText != nil && !searchText!.isEmpty {
                    if !response.content.isEmpty {
                        completion(.success(response))
                        return
                    }
                    
                    self.searchInOtherFields(page: page, pageSize: pageSize, searchText: searchText!, completion: completion)
                } else {
                    completion(.success(response))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func searchInOtherFields(page: Int, pageSize: Int, searchText: String, completion: @escaping (Result<DigimonResponse, Error>) -> Void) {
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchFields = ["type", "attribute", "level", "field"]
        
        let group = DispatchGroup()
        var allResults: [Digimon] = []
        var searchError: Error?
        
        for field in searchFields {
            group.enter()
            
            let urlString = "\(baseURL)/digimon?page=\(page)&pageSize=\(pageSize)&\(field)=\(encodedText)"
            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }
            
            performRequest(url: url) { (result: Result<DigimonResponse, Error>) in
                defer { group.leave() }
                
                switch result {
                case .success(let response):
                    allResults.append(contentsOf: response.content)
                case .failure(let error):
                    searchError = error
                }
            }
        }
        
        group.notify(queue: .main) {
            if !allResults.isEmpty {
                // Remove duplicates based on ID
                let uniqueResults = Array(Set(allResults.map { $0.id }))
                    .compactMap { id in allResults.first(where: { $0.id == id }) }
                    .sorted { $0.id < $1.id }
                
                let response = DigimonResponse(
                    content: Array(uniqueResults.prefix(pageSize)),
                    pageable: nil
                )
                completion(.success(response))
            } else if let error = searchError {
                completion(.failure(error))
            } else {
                completion(.success(DigimonResponse(content: [], pageable: nil)))
            }
        }
    }
    
    func fetchDigimonDetail(id: Int, completion: @escaping (Result<DigimonDetail, Error>) -> Void) {
        let urlString = "\(baseURL)/digimon/\(id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    private func performRequest<T: Codable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet {
                    completion(.failure(NetworkError.noInternetConnection))
                } else {
                    completion(.failure(NetworkError.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(NetworkError.decodingError(error)))
            }
        }.resume()
    }
}

extension Digimon: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Digimon, rhs: Digimon) -> Bool {
        return lhs.id == rhs.id
    }
}

enum NetworkError: LocalizedError {
    case noInternetConnection
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case noData
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .noData:
            return "No data received from server."
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        }
    }
}
