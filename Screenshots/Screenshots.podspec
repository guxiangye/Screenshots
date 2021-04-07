#
#  Be sure to run `pod spec lint YEAFNRequestManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "Screenshots"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of Screenshots."
  spec.homepage     = "https://github.com/guxiangye"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "guxiangyee" => "guxiangyee@163.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/guxiangye/Screenshots.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  spec.source_files = 'Classes/Screenshots.h'
  
  spec.subspec 'GCDWebServer' do |s|
    s.source_files  = "Classes/GCDWebServer/**/*.{h,m}"
    s.public_header_files = 'Classes/GCDWebServer/**/*.h'
  end
  
  spec.subspec 'VTAntiScreenCapture' do |s|
    s.source_files  = "Classes/VTAntiScreenCapture/**/*.{h,m}"
    s.public_header_files = 'Classes/VTAntiScreenCapture/**/*.h'
  end

end
