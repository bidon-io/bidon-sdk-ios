//
//  ConfigurationRequestBuilder.swift
//  Bidon
//
//  Created by Bidon Team on 11.08.2022.
//

import Foundation


final class ConfigurationRequestBuilder: BaseRequestBuilder {
    var adapters: AdaptersInfo {
        let adapters: [Adapter] = adaptersRepository.all()

        return AdaptersInfo(adapters: adapters)
    }
}
