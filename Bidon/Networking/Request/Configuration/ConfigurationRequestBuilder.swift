//
//  ConfigurationRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


final class ConfigurationRequestBuilder: BaseRequestBuilder {
    var adapters: AdaptersInfo {
        let adapters: [Adapter] = adaptersRepository.ids.compactMap { key in
            adaptersRepository[key] as Adapter?
        }
        return AdaptersInfo(adapters: adapters)
    }
}
