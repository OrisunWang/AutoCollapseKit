Pod::Spec.new do |s|
  # Public release metadata; source tags match the published semantic version.
  s.name = 'AutoCollapseKit'
  s.version = '0.1.0'
  s.summary = 'Opt-in hidden constraint folding for UIKit, SnapKit and Masonry.'
  s.description = <<-DESC
    Mark selected Auto Layout constraints to collapse when their owning view hides,
    and restore the latest expanded constants when it becomes visible. Core supports
    native NSLayoutConstraint; independent SnapKit and Masonry adapters can be used
    separately or together through CocoaPods subspecs.
  DESC
  s.homepage = 'https://github.com/OrisunWang/AutoCollapseKit'
  s.author = { 'Orisun Wang' => 'orisun.wang@gmail.com' }
  s.source = { :git => 'https://github.com/OrisunWang/AutoCollapseKit.git', :tag => s.version.to_s }
  # MIT publication was explicitly approved by the project owner.
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.0']
  s.requires_arc = true
  s.default_subspecs = 'Core'

  # Pure Objective-C users do not compile Swift or install either layout library.
  s.subspec 'Core' do |core|
    core.source_files = 'Sources/Core/**/*.{h,m}'
    core.public_header_files = 'Sources/Core/**/*.h'
    core.frameworks = 'UIKit'
  end

  # Only the selected adapter contributes its third-party dependency and sources.
  s.subspec 'SnapKit' do |adapter|
    adapter.source_files = 'Sources/SnapKit/**/*.swift'
    adapter.dependency 'AutoCollapseKit/Core'
    adapter.dependency 'SnapKit', '~> 5.6'
  end

  s.subspec 'Masonry' do |adapter|
    adapter.source_files = 'Sources/Masonry/**/*.{h,m}'
    adapter.public_header_files = 'Sources/Masonry/**/*.h'
    adapter.dependency 'AutoCollapseKit/Core'
    adapter.dependency 'Masonry', '~> 1.1'
  end
end
