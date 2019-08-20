Pod::Spec.new do |s|
  s.name             = "CloudCore"
  s.summary          = "Framework that enables synchronization between CloudKit and Core Data."
  s.version          = "3.0"
  s.homepage         = "https://github.com/deeje/CloudCore"
  s.license          = 'MIT'
  s.author           = { "deeje" => "deeje@mac.com", "Vasily Ulianov" => "vasily@me.com" }
  s.source           = {
    :git => "https://github.com/deeje/CloudCore.git",
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'Source/**/*.swift'

  s.ios.frameworks = 'Foundation', 'CloudKit', 'CoreData'
  s.osx.frameworks = 'Foundation', 'CloudKit', 'CoreData'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  s.documentation_url = 'http://cocoadocs.org/docsets/CloudCore/'
end
