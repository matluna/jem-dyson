//
//  UserDomain.swift
//  Rkit
//
//  Created by bamsham on 2018-03-07.
//  Copyright © 2018 Syni. All rights reserved.
//

import Foundation

public struct UserDomain : Codable
{
    public var  id : String?
    public var  type : String?
    
    public init()
    {
        id = nil
        type = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
    }
}
