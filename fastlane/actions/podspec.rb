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

      IOS_MIN_VERSIONS = {
          "BidonAdapterIronSource" => "13.0",
          "ISBidonCustomAdapter"   => "13.0",
          "BidonAdapterMyTarget"   => "12.4",
          "BidonAdapterYandex"     => "13.0",
          "BidonAdapterDTExchange" => "13.0",
          "BidonAdapterUnityAds"   => "13.0"
      }

      def self.run(params)
        podfile = Pod::Podfile.from_file(params[:podfile])

        s3_region = params[:s3_region]
        s3_bucket = params[:s3_bucket]

        dependencies = podfile.target_definitions[params[:name]].nil? ? [] : podfile.target_definitions[params[:name]].dependencies.map do |dep|
          Dependency.new(
            name: dep.name.split("/").first,
            version: dep.to_s.scan(/\((.*)\)/m).flatten[0]
          )
        end

        # Remove Stack dependencies from adapters and BidMachine bidding adapters
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
          spec.license = { type: "Copyright", text: "Copyright #{Time.new.year}. Bidon Inc." }
          spec.author = { "Bidon Inc." => "https://bidon.org" }

          ios_version = IOS_MIN_VERSIONS.fetch(params[:name], "12.0")
          spec.platform = :ios, ios_version

          if params[:is_development_pod]
            spec.source = { git: "" }
            spec.source_files = params[:name] == "Bidon" ? 'Bidon/**/*.{h,m,swift}' : params[:name] + '/**/*.{h,m,swift}'
            spec.static_framework = true
          else
            spec.source = { http: "https://s3-#{s3_region}.amazonaws.com/#{s3_bucket}/#{spec.name}/#{CGI.escape(params[:version])}/#{spec.name}.zip" }
          end

          spec.swift_versions = ["4.0", "4.2", "5.0"]

          unless params[:is_adapter]
            spec.resource_bundles = { "BidonPrivacyInfo" => "#{spec.name}-#{CGI.escape(params[:version])}/Bidon.xcframework/ios-arm64/**/*.xcprivacy" }
          end

          spec.vendored_frameworks = [params[:vendored_frameworks]]

          dependencies.each do |dep|
            if dep.version.nil?
              spec.dependency dep.name
            else
              spec.dependency dep.name, dep.version
            end
          end

          root = params[:podfile].split('/')[0...-1].join('/') + "/Pods"

          pod_target_xcconfig = {
            "OTHER_LDFLAGS" => "-lObjC",
            "VALID_ARCHS[sdk=iphoneos*]" => "arm64 armv7"
          }

          user_target_xcconfig = {
            "OTHER_LDFLAGS" => "-lObjC"
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

        # Convert podspec to hash and debug print
        podspec_hash = podspec.to_hash
        UI.message("Podspec hash: #{podspec_hash}")

        # Write podspec to file
        File.open(params[:path] + "/" + params[:name] + ".podspec.json", "w") do |f|
          f.write(JSON.pretty_generate(podspec_hash))
        end
      end

      def self.description
        "Generate Podspec by using of project Podfile"
      end

      def self.is_apple_silicon_compatible(dependencies, root)
        dependencies.inject(true) do |result, dep|
          Dir.glob(root + "/" + dep.name + "/**/*").inject(result) do |result, path|
            components = path.split('/')
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
        dependencies.inject(true) do |result, dep|
          Dir.glob(root + "/" + dep.name + "/**/*").inject(result) do |result, path|
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
              UI.user_error!("No version for Podspec given, pass using `version: 'x.y.z'`") unless (value and not value.empty?)
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
            optional: true
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
              UI.user_error!("No AWS S3 region given, pass using `s3_region: 'us-east-1'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :s3_bucket,
            description: "AWS S3 bucket where file is located",
            verify_block: proc do |value|
              UI.user_error!("No AWS S3 bucket given, pass using `s3_bucket: 'your-bucket'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :path,
            description: "Path where podspec file will be generated",
            verify_block: proc do |value|
              UI.user_error!("No path for podspec file given, pass using `path: '/User/../'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :vendored_frameworks,
            description: "List of vendored frameworks",
            verify_block: proc do |value|
              UI.user_error!("No vendored frameworks given, pass using `vendored_frameworks: ['path/to/framework']`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :name,
            description: "Pod name",
            verify_block: proc do |value|
              UI.user_error!("No pod name given, pass using `name: 'MyPod'`") unless (value and not value.empty?)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :is_development_pod,
            description: "Is development pod",
            default_value: false,
            optional: true,
            is_string: false
          )
        ]
      end

      def self.output
        [
          ['PODSPEC_CUSTOM_VALUE', '']
        ]
      end

      def self.return_value
        nil
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
