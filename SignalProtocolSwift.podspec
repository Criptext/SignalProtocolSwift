Pod::Spec.new do |s|
  s.name             = 'SignalProtocolSwift'
  s.version          = '0.1'
  s.summary          = 'SignalProtocolSwift is a wrapper of the Signal Protocol written in Objective-C.'
 
  s.description      = <<-DESC
SignalProtocolSwift is a wrapper of the Signal Protocol written in Objective-C. This works for Swift Projects.
                       DESC
 
  s.homepage         = 'https://github.com/Criptext/SignalProtocolSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Daniel Tigse' => 'daniel@criptext.com' }
  s.source           = { :git => 'https://github.com/Criptext/SignalProtocolSwift.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '10.0'
  s.source_files = 'SignalProtocolFramework/**/*.{c,h,m}'
  s.public_header_files = "SignalProtocolFramework/**/*.{h}"
  # s.pod_target_xcconfig = {
  #   'OTHER_LDFLAGS' => '$(inherited)'
  # }
  s.user_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
  #s.requires_arc     = true
  #s.library    = 'c++'
  #s.frameworks = 'Foundation'
  #s.platform     = :ios, '10.0'
end