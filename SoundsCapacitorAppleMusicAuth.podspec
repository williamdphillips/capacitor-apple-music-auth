Pod::Spec.new do |s|
  s.name = 'SoundsCapacitorAppleMusicAuth'
  s.version = '1.0.0'
  s.summary = 'Capacitor plugin for native Apple Music authorization on iOS'
  s.license = 'MIT'
  s.homepage = 'https://github.com/williamdphillips/capacitor-plugins'
  s.author = 'SOUNDS STUDIOS TECHNOLOGIES LLC'
  s.source = { :git => 'https://github.com/williamdphillips/capacitor-plugins', :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  s.ios.frameworks = 'MusicKit'
end
