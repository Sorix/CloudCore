Pod::Spec.new do |s|
  s.name             = "CloudCore"
  s.summary          = "Framework that enables synchronization between CloudKit (iCloud) and Core Data. Can be used as CloudKit caching mechanism."
  s.version          = "2.0.0"
  s.homepage         = "https://github.com/sorix/CloudCore"
  s.license          = 'MIT'
  s.author           = { "Vasily Ulianov" => "vasily@me.com" }
  s.source           = {
    :git => "https://github.com/sorix/CloudCore.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'Source/**/*.swift'

  s.ios.frameworks = 'Foundation', 'CloudKit', 'CoreData'
  s.osx.frameworks = 'Foundation', 'CloudKit', 'CoreData'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  s.documentation_url = 'http://cocoadocs.org/docsets/CloudCore/'
end
