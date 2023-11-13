require 'fileutils'
require 'cocoapods-core'
require 'plist'
require 'rest-client'
require 'json'

module Fastlane
  module Actions
    module SharedValues
      GENERATE_SANDBOX_CONSTANTS_VALUE = :GENERATE_SANDBOX_CONSTANTS_CUSTOM_VALUE
    end

    class GenerateSandboxConstantsAction < Action
      def self.run(params)
        generate_constants(params)
        generate_plist(params)
      end

      def self.description
        "Generate Constants.swift based on ENV values"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :path,
            description: "Path to Constants.swift",
            verify_block: proc do |value|
              UI.user_error!("No path for Constants.swift") unless (value and not value.empty?)
            end
          )
        ]
      end

      def self.generate_constants(params)
        File.open(params[:path] + "/Shared/Constants.swift", "w") { |f| 
          f.write "import Foundation\n\n" 
          f.write "struct Constants {\n" 
          f.write "\tstruct AppsFlyer {\n" 
          f.write "\t\tstatic let devKey = \"#{ENV["APPSFLYER_DEV_KEY"]}\"\n" 
          f.write "\t\tstatic let appId = \"#{ENV["APPSFLYER_APP_ID"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Bidon {\n" 
          f.write "\t\tstatic let appKey = \"#{ENV["BIDON_APP_KEY"]}\"\n" 
          f.write "\t\tstatic let baseURL = \"#{ENV["BIDON_BASE_URL"]}\"\n"
          f.write "\t\tstatic let stagingFirstURL = \"#{ENV["BIDON_STAGING_1_URL"]}\"\n" 
          f.write "\t\tstatic let stagingSecondURL = \"#{ENV["BIDON_STAGING_2_URL"]}\"\n" 
          f.write "\t\tstatic let stagingUser = \"#{ENV["BIDON_STAGING_USER"]}\"\n" 
          f.write "\t\tstatic let stagingPassword = \"#{ENV["BIDON_STAGING_PASSWORD"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Facebook {\n" 
          f.write "\t\tstatic let appId = \"#{ENV["FACEBOOK_APP_ID"]}\"\n" 
          f.write "\t\tstatic let clientToken = \"#{ENV["FACEBOOK_CLIENT_TOKEN"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct AdMob {\n" 
          f.write "\t\tstatic let appId = \"#{ENV["ADMOB_APP_ID"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Appodeal {\n" 
          f.write "\t\tstatic let appKey = \"#{ENV["BIDON_APP_KEY"]}\"\n" 
          f.write "\t}\n" 
          f.write "}" 
        }
      end

      def self.generate_plist(params)
        response = RestClient.get('https://mw-backend.appodeal.com/v1/skadnetwork')
        skadids = JSON.parse(response.body).map { |item| item["ids"] }.flatten.uniq        

        info_plist_content = {
          'GADApplicationIdentifier' => ENV["ADMOB_APP_ID"],
          'CFBundleURLTypes' => [
            { 
              'CFBundleURLSchemes' => ['fb' + ENV["FACEBOOK_APP_ID"]] 
            }
          ],
          'LSApplicationQueriesSchemes' => [
            'fbapi',
            'fb-messenger-share-api',
          ],
          'FacebookAppID' => ENV["FACEBOOK_APP_ID"],
          'FacebookClientToken' => ENV["FACEBOOK_CLIENT_TOKEN"],
          'FacebookDisplayName' => ENV["FACEBOOK_DISPLAY_NAME"],
          'NSAppTransportSecurity' => {
            'NSAllowsArbitraryLoads' => true
          },
          'SKAdNetworkItems' => skadids.map { |id| { 'SKAdNetworkIdentifier' => id } },
        }

        plist_xml = Plist::Emit.dump(info_plist_content)

        File.open(params[:path] + '/Info.plist', 'w') do |file|
          file.write(plist_xml)
        end
      end

      def self.output
        [
          ['GENERATE_SANDBOX_CONSTANTS_CUSTOM_VALUE', '']
        ]
      end

      def self.authors
        ["Appodeal"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end