require 'fileutils'
require 'cocoapods-core'
require 'json'
require 'cgi'


module Fastlane
  module Actions
    module SharedValues
      PODSPEC_CUSTOM_VALUE = :PODSPEC_CUSTOM_VALUE
    end

    class PodspecAction < Action
      Dependency = Struct.new("PodspecDependency", :name, :version, keyword_init: true)

      def self.run(params)
        podfile = Pod::Podfile.from_file(params[:podfile])

        s3_region = params[:s3_region]
        s3_bucket = params[:s3_bucket]
         
        dependencies =  podfile.target_definitions[params[:name]].nil? ? [] : podfile.target_definitions[params[:name]].dependencies.map do |dep| 
          Dependency.new(
            name: dep.name.split("/").first,
            version: dep.to_s.scan(/\((.*)\)/m).flatten[0]
          )
        end

        # Removes Stack dependencies from adapters 
        # And BidMachine bidding adapters
        if params[:is_adapter] 
          dependencies.append(Dependency.new(
            name: "Bidon",
            version: params[:sdk_version]
          ))
        end

        podspec = Pod::Specification.new do |spec|
          spec.name = params[:name]
          spec.version = params[:version]
          spec.summary = params[:name] == "Bidon" ? "Bidon iOS Framework" : "Bidon adapter for #{params[:name]}"
          spec.description = "Makes the top mobile mediation SDKs more transparent"
          spec.homepage = "https://bidon.org"
          spec.license = { :type => "Copyright", :text => "Copyright #{Time.new.year}. Bidon Inc." }
          spec.author = { "Bidon Inc." => "https://http://bidon.org" }
          spec.platform = :ios, "12.0"
          spec.source = { :http => "https://s3-#{s3_region}.amazonaws.com/#{s3_bucket}/#{spec.name}/#{CGI.escape(params[:version])}/#{spec.name}.zip" }
          spec.swift_versions = "4.0", "4.2", "5.0"
        
          spec.vendored_frameworks = params[:vendored_frameworks]
            
          dependencies.each do | dep |
            if dep.version.nil? 
              spec.dependency dep.name
            else 
              spec.dependency dep.name, dep.version
            end
          end

          root = params[:podfile].split('/')[0...-1].join('/') + "/Pods"

          pod_target_xcconfig = {
            "OTHER_LDFLAGS": "-lObjC",
            "VALID_ARCHS[sdk=iphoneos*]": "arm64 armv7",
          }

          user_target_xcconfig = {
            "OTHER_LDFLAGS": "-lObjC"
          }

          if self.is_apple_silicon_compatible(dependencies, root) 
            pod_target_xcconfig["VALID_ARCHS[sdk=iphonesimulator*]"] = "x86_64 arm64"
          elsif self.is_legacy_framework(dependencies, root)
            pod_target_xcconfig["VALID_ARCHS[sdk=iphonesimulator*]"] = "x86_64"
            user_target_xcconfig["VALID_ARCHS[sdk=iphoneos*]"] = "arm64 armv7"
            user_target_xcconfig["VALID_ARCHS[sdk=iphonesimulator*]"] = "x86_64"
          else
            pod_target_xcconfig["VALID_ARCHS[sdk=iphonesimulator*]"] = "x86_64"
          end

          spec.pod_target_xcconfig = pod_target_xcconfig
          spec.user_target_xcconfig = user_target_xcconfig
        end
        
        File.open(params[:path] + "/" + params[:name] + ".podspec.json", "w") do |f|
          f.write(JSON.pretty_generate(podspec))
        end
      end

      def self.description
        "Generate Podspec by using of project Podfile"
      end

      def self.is_apple_silicon_compatible(dependencies, root) 
        return dependencies.inject(true) do |result, dep|
          return  Dir.glob(root + "/" + dep.name + "/**/*").inject(result) do |result, path|
            components = path.split('/')
            # Search xcframeworks first and read it info.plist
            if components[-1] == 'Info.plist' && components[-2].end_with?(".xcframework")
              plist = Xcodeproj::Plist.read_from_path(path)
              supports_arm_64_simulator = plist["AvailableLibraries"]
                .select { |lib| lib["SupportedPlatformVariant"] == "simulator" && lib["SupportedArchitectures"].include?("arm64") }
                .length > 0
              result && supports_arm_64_simulator
            elsif components[-1].end_with?(".framework") && !path.include?("xcframework")
              result && false
            else 
              result && true
            end
          end
        end
      end

      def self.is_legacy_framework(dependencies, root)
        return dependencies.inject(true) do |result, dep|
          return  Dir.glob(root + "/" + dep.name + "/**/*").inject(result) do |result, path|
            components = path.split('/')
            result && components[-1].end_with?(".framework") && !path.include?("xcframework")
          end
        end
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: "Version",
            verify_block: proc do |value|
              UI.user_error!("No version for Podspec given, pass using `version: 'x.y.z`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :is_adapter,
            description: "Identifies that podspec is adapter or not",
            default_value: false,
            optional: true,
            is_string: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :sdk_version,
            description: "SDK version",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :podfile,
            description: "Path to podfile",
            verify_block: proc do |value|
              UI.user_error!("No Podfile path given, pass using `podfile: '/User/../Podfile'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :s3_region,
            description: "AWS S3 region where file is located",
            verify_block: proc do |value|
              UI.user_error!("No AWS S3 region given, pass using `s3_region: us-east-1`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :s3_bucket,
            description: "AWS S3 bucket where file is located",
            verify_block: proc do |value|
              UI.user_error!("No AWS S3 bucket given, pass using `s3_bucket: my-bucket`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :name,
            description: "Name of Podspec",
            verify_block: proc do |value|
              UI.user_error!("No Podspec path given, pass using `name: 'name'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :path,
            description: "Path to Podspec file",
            verify_block: proc do |value|
              UI.user_error!("No Podspec path given, pass using `path: '/User/../*.podspec'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :vendored_frameworks,
            description: "Vendored frameworks",
            is_string: false,
            default_value: []
          )
        ]
      end

      def self.output
        [
          ['PODSPEC_CUSTOM_VALUE', '']
        ]
      end

      def self.authors
        ["Bidon Team"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end