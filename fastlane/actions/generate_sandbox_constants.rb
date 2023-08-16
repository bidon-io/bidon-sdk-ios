require 'fileutils'
require 'cocoapods-core'


module Fastlane
  module Actions
    module SharedValues
      GENERATE_SANDBOX_CONSTANTS_VALUE = :GENERATE_SANDBOX_CONSTANTS_CUSTOM_VALUE
    end

    class GenerateSandboxConstantsAction < Action
      def self.run(params)
        File.open(params[:path] + "/Constants.swift", "w") { |f| 
          f.write "import Foundation\n\n" 
          f.write "struct Constants {\n" 
          f.write "\tstruct AppsFlyer {\n" 
          f.write "\t\tstatic let devKey = \"#{ENV["APPSFLYER_DEV_KEY"]}\"\n" 
          f.write "\t\tstatic let appId = \"#{ENV["APPSFLYER_APP_ID"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Bidon {\n" 
          f.write "\t\tstatic let appKey = \"#{ENV["BIDON_APP_KEY"]}\"\n" 
          f.write "\t\tstatic let baseURL = \"#{ENV["BIDON_BASE_URL"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Facebook {\n" 
          f.write "\t\tstatic let appId = \"#{ENV["FACEBOOK_APP_ID"]}\"\n" 
          f.write "\t\tstatic let clientToken = \"#{ENV["FACEBOOK_CLIENT_TOKEN"]}\"\n" 
          f.write "\t}\n\n" 
          f.write "\tstruct Appodeal {\n" 
          f.write "\t\tstatic let appKey = \"#{ENV["BIDON_APP_KEY"]}\"\n" 
          f.write "\t}\n" 
          f.write "}" 
        }
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