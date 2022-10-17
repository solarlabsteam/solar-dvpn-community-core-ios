//
//  ContinentDecoder.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 03.10.2022.
//

import Foundation

// MARK: - ContinentDecoder

final class ContinentDecoder {
    static let shared = ContinentDecoder()
    
    private var countryCodeToContinent: [String: String] = [:]
    
    init() {
        let fileName = "continents"
        guard let countriesExtraURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return
        }
        do {
            let countriesExtraData = try Data(contentsOf: countriesExtraURL, options: [])
            let countriesExtra = try JSONDecoder().decode([CountryExtra].self, from: countriesExtraData)
            
            for countryExtra in countriesExtra {
                let countryCode = countryExtra.alpha2.uppercased()
                countryCodeToContinent[countryCode] = countryExtra.continent
            }
            
        } catch {}
    }
}

extension ContinentDecoder {
    func getContinent(for countryCode: String) -> Continent? {
        let continentCode = countryCodeToContinent[countryCode.uppercased()]
        
        return Continent(rawValue: continentCode ?? "")
    }
}
