// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  Deployments.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 9/22/24.
//
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let deployments = try? JSONDecoder().decode(DeploymentsWrapper.self, from: jsonData)

import Foundation

// MARK: - Properties and Types
struct Deployment: Codable {
    let id, type, name: String
    let sku: Sku
    let properties: Properties
    let systemData: SystemData
    let etag: String
    
    // MARK: -- Sku --
    struct Sku: Codable {
        let name: String
        let capacity: Int
    }
    
    // MARK: -- Properties --
    struct Properties: Codable {
        let model: Model
        let versionUpgradeOption: String
        let capabilities: Capabilities
        let raiPolicyName, provisioningState: String
        let rateLimits: [RateLimit]
        
        // MARK: -- Model --
        struct Model: Codable {
            let format, name, version: String
        }
        
        // MARK: -- Capabilities --
        struct Capabilities: Codable {
            let chatCompletion, completion, imageGenerations, imageVariations: String?
        }
        
        // MARK: -- RateLimit --
        struct RateLimit: Codable {
            let key: Key
            let renewalPeriod, count: Int
            
            enum Key: String, Codable {
                case request = "request"
                case token = "token"
            }
        }
    }
    
    // MARK: -- SystemData --
    struct SystemData: Codable {
        let createdBy, createdByType, createdAt, lastModifiedBy: String
        let lastModifiedByType, lastModifiedAt: String
    }
}

// MARK: - Public Static Properties
extension Deployment {
    /// Current AI model deployment
    public fileprivate(set) static var current: Deployment?
    
    /// Set current deployment
    /// - Parameter deployment: the deployment to set current
    public static func setCurrent(_ deployment: Deployment?) {
        self.current = deployment
    }
}

// MARK: - Computed Properties
extension Deployment {
    var title: String {
        "\(name.replacingOccurrences(of: "-", with: " ")) (\(properties.model.name))"
    }
}

// MARK: - Comparable
extension Deployment: Comparable {
    static func < (lhs: Deployment, rhs: Deployment) -> Bool {
        lhs.name < rhs.name
    }
    
    static func == (lhs: Deployment, rhs: Deployment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Properties
public struct DeploymentsWrapper: Codable {
    let value: [Deployment]
}

// MARK: - Models Response
public struct ModelsResponse: Codable {
    let data: [Model]
    
    struct Model: Codable {
        let id: String
    }
}
