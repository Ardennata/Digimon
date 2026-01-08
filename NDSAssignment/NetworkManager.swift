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
        
        guard let text = searchText, !text.isEmpty else {
            fetchNormalDigimons(page: page, pageSize: pageSize, completion: completion)
            return
        }
        
        searchDigimons(searchText: text, page: page, pageSize: pageSize, completion: completion)
    }
    
    private func fetchNormalDigimons(page: Int, pageSize: Int, completion: @escaping (Result<DigimonResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/digimon?page=\(page)&pageSize=\(pageSize)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        performRequest(url: url, completion: completion)
    }
    
    private func searchDigimons(searchText: String, page: Int, pageSize: Int, completion: @escaping (Result<DigimonResponse, Error>) -> Void) {
        
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let searchURLs = [
            "\(baseURL)/digimon?page=0&pageSize=50&name=\(encodedText)",
            "\(baseURL)/digimon?page=0&pageSize=50&attribute=\(encodedText)",
            "\(baseURL)/digimon?page=0&pageSize=50&level=\(encodedText)"
        ]
        
        var allDigimons: [Digimon] = []
        let group = DispatchGroup()
        
        for urlString in searchURLs {
            guard let url = URL(string: urlString) else { continue }
            
            group.enter()
            
            performRequest(url: url) { (result: Result<DigimonResponse, Error>) in
                if case .success(let response) = result {
                    allDigimons.append(contentsOf: response.content)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Hilangkan duplikat
            let uniqueDigimons = self.removeDuplicates(from: allDigimons)
            
            // Buat response
            let response = DigimonResponse(
                content: uniqueDigimons,
                pageable: nil
            )
            
            completion(.success(response))
        }
    }
    
    private func removeDuplicates(from digimons: [Digimon]) -> [Digimon] {
        var seen: Set<Int> = []
        var unique: [Digimon] = []
        
        for digimon in digimons {
            if !seen.contains(digimon.id) {
                seen.insert(digimon.id)
                unique.append(digimon)
            }
        }
        
        return unique.sorted { $0.name < $1.name }
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
