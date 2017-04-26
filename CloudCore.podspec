Pod::Spec.new do |s|
  s.name             = "CloudCore"
  s.summary          = "Framework that enables syncing between iCloud (CloudKit) and Core Data"
  s.version          = "0.1.2"
  s.homepage         = "https://github.com/sorix/CloudCore"
  s.license          = 'MIT'
  s.author           = { "Vasily Ulianov" => "vasily@me.com" }
  s.source           = {
    :git => "https://github.com/sorix/CloudCore.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'

  s.ios.source_files = 'Sources/**/*.swift'
  # s.tvos.source_files = 'Sources/**/*.swift'
  s.osx.source_files = 'Sources/**/*.swift'

  s.ios.frameworks = 'Foundation', 'CloudKit', 'CoreData'
  s.osx.frameworks = 'Foundation', 'CloudKit', 'CoreData'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
  s.documentation_url = 'https://github.com/Sorix/CloudCore/wiki'
end
