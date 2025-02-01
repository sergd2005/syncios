//
//  SIFile+extensions.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Foundation

enum SIFileError: Error {
    case parsingDataFailed
}

extension SIFile {
    func jsonData() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["contents" : contents], options: .prettyPrinted)
    }
    
    func fromJSONData(_ data: Data) throws {
        guard let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else { throw SIFileError.parsingDataFailed }
        contents = result["contents"] as? String
    }
}
