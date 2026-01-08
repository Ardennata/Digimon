//
//  DigimonModel.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import Foundation

struct DigimonResponse: Codable {
    let content: [Digimon]
    let pageable: Pageable?
}

struct Digimon: Codable {
    let id: Int
    let name: String
    let href: String?
    let image: String?
    
    var imageURL: URL? {
        guard let image = image else { return nil }
        return URL(string: image)
    }
}

struct Pageable: Codable {
    let currentPage: Int?
    let elementsOnPage: Int?
    let totalElements: Int?
    let totalPages: Int?
    let previousPage: String?
    let nextPage: String?
}

struct DigimonDetail: Codable {
    let id: Int
    let name: String
    let xAntibody: Bool?
    let images: [DigimonImage]?
    let levels: [Level]?
    let types: [DigimonType]?
    let attributes: [DigimonAttribute]?
    let fields: [Field]?
    let descriptions: [Description]?
    let skills: [Skill]?
}

struct DigimonImage: Codable {
    let href: String
    let transparent: Bool?
}

struct Level: Codable {
    let id: Int?
    let level: String?
}

struct DigimonType: Codable {
    let id: Int?
    let type: String?
}

struct DigimonAttribute: Codable {
    let id: Int?
    let attribute: String?
}

struct Field: Codable {
    let id: Int?
    let field: String?
    let image: String?
}

struct Description: Codable {
    let origin: String?
    let language: String?
    let description: String?
}

struct Skill: Codable {
    let id: Int?
    let skill: String?
    let translation: String?
    let description: String?
}
