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
      Dependency = Struct.new("PodspecDependency", :name, :versions, keyword_init: true)

      IOS_MIN_VERSIONS = {
          "BidonAdapterIronSource" => "13.0",
          "ISBidonCustomAdapter"   => "13.0",
          "BidonAdapterMyTarget"   => "14.0",
          "BidonAdapterYandex"     => "13.0",
          "BidonAdapterDTExchange" => "13.0",
          "BidonAdapterUnityAds"   => "13.0",
          "BidonAdapterMoloco"     => "13.0"
      }

      def self.run(params)
        podfile = Pod::Podfile.from_file(params[:podfile])

        # Read resolved versions from Podfile.lock to pin adapter SDK deps exactly
        lock_path = params[:podfile].split('/')[0...-1].join('/') + "/Podfile.lock"
        resolved_versions = self.read_lock_versions(lock_path)

        s3_region = params[:s3_region]
        s3_bucket = params[:s3_bucket]

        dependencies = podfile.target_definitions[params[:name]].nil? ? [] : podfile.target_definitions[params[:name]].dependencies.map do |dep|
          dep_name =
            if dep.name == "IronSourceSDK/Ads"
              dep.name
            else
              dep.name.split("/").first
            end

          v = dep.to_s.scan(/\((.*)\)/m).flatten[0]

          Dependency.new(
            name: dep_name,
            versions: (v.nil? || v.empty?) ? [] : [v]
          )
        end

        if params[:is_adapter]
          dependencies = dependencies.map do |d|
            next d if d.name == "Bidon"
            resolved = resolved_versions[d.name]
            if resolved && !resolved.to_s.empty?
              Dependency.new(name: d.name, versions: ["= #{resolved}"])
            else
              d
            end
          end

          last_release, max_release = self.read_sdk_versions_from_constants(params[:podfile])

          lower = (last_release && !last_release.empty?) ? last_release : params[:sdk_version]
          upper = (max_release && !max_release.empty?) ? max_release : nil

          bidon_constraints = []
          bidon_constraints << ">= #{lower}" if lower && !lower.empty?
          bidon_constraints << "< #{upper}"  if upper && !upper.empty?

          dependencies.append(Dependency.new(
            name: "Bidon",
            versions: bidon_constraints
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
            spec.source = { http: "https://s3-eu-central-1.amazonaws.com/#{s3_bucket}/#{spec.name}/#{CGI.escape(params[:version])}/#{spec.name}.zip" }
          end

          spec.swift_versions = ["4.0", "4.2", "5.0"]

          unless params[:is_adapter]
            spec.resource_bundles = { "BidonPrivacyInfo" => "#{spec.name}-#{CGI.escape(params[:version])}/Bidon.xcframework/ios-arm64/**/*.xcprivacy" }
          end

          spec.vendored_frameworks = [params[:vendored_frameworks]]

          dependencies.each do |dep|
            if dep.versions.nil? || dep.versions.empty?
              spec.dependency dep.name
            else
              spec.dependency dep.name, *dep.versions
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

      def self.read_sdk_versions_from_constants(podfile_path)
        begin
          root = File.dirname(podfile_path)
          path = File.join(root, "Bidon", "Shared", "Constants.swift")
          return [nil, nil] unless File.exist?(path)

          content = File.read(path)

          last_release = content.match(/sdkVersionLastRelease\s*:\s*String\s*=\s*"([^"]+)"/)
          max_release = content.match(/maxSdkReleaseVersion\s*:\s*String\s*=\s*"([^"]+)"/)

          last_release_value = last_release ? last_release[1] : nil
          max_release_value = max_release ? max_release[1] : nil

          UI.message("sdkVersionLastRelease not found in #{path}, falling back to sdk_version param") if last_release_value.nil? || last_release_value.empty?
          UI.message("maxSdkReleaseVersion not found in #{path}") if max_release_value.nil? || max_release_value.empty?

          [last_release_value, max_release_value]
        rescue => e
          UI.message("Failed to read SDK versions from Constants.swift: #{e}")
          [nil, nil]
        end
      end

      def self.read_sdk_last_release_from_constants(podfile_path)
        begin
          root = File.dirname(podfile_path)
          path = File.join(root, "Bidon", "Shared", "Constants.swift")
          return nil unless File.exist?(path)

          content = File.read(path)
          match = content.match(/sdkVersionLastRelease\s*:\s*String\s*=\s*"([^"]+)"/)
          if match
            match[1]
          else
            UI.message("sdkVersionLastRelease not found in #{path}, falling back to sdk_version param")
            nil
          end
        rescue => e
          UI.message("Failed to read sdkVersionLastRelease from Constants.swift: #{e}")
          nil
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

      # Parse Podfile.lock and extract resolved versions from PODS section
      def self.read_lock_versions(lock_path)
        versions = {}
        return versions unless File.exist?(lock_path)
        in_pods = false
        File.foreach(lock_path) do |line|
          if line.start_with?("PODS:")
            in_pods = true
            next
          end
          if in_pods && line.match?(/^[A-Z][A-Z ]+:/)
            in_pods = false
          end
          if in_pods && line.start_with?("  - ")
            entry = line.sub(/^  - /, "").strip
            name, ver = entry.split(" (", 2)
            if name && ver
              v = ver.to_s.delete(")").strip
              # sanitize: drop common operators and any non [0-9A-Za-z.-]
              v = v.sub(/^~>\s*/, "").sub(/^>=\s*/, "").sub(/^<=\s*/, "").sub(/^==\s*/, "").sub(/^=\s*/, "")
              v = v.gsub(/[^0-9A-Za-z\.-]/, "")
              versions[name] = v
            end
          end
        end
        versions
      end
    end
  end
end
