require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

folly_version = '2021.07.22.00'

Pod::Spec.new do |s|
  s.name         = "SvgaPlayerRN"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/WangJM001/svga-player-rn.git", :tag => "#{s.version}" }

  s.source_files    = "ios/**/*.{h,m,mm,swift}"
  s.private_header_files = "ios/**/*.h"

  s.dependency "SVGAPlayer"
  s.dependency 'Protobuf', '3.22.1'

  install_modules_dependencies(s)
end
