#
# Be sure to run `pod lib lint ZZHNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZZHNetwork'
  s.version          = '1.4.3'
  s.summary          = 'SDK for convenient network'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        '这是一个方便的网络请求SDK'
                        '基于AFNetwork进行了二次封装'
                       DESC

  s.homepage         = 'https://github.com/375003148/ZZHNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '375003148' => '375003148@qq.com' }
  s.source           = { :git => 'https://github.com/375003148/ZZHNetwork.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  # 使用到的工程文件
  s.source_files = 'ZZHNetwork/Header/*.{h,m}', 'ZZHNetwork/Private/*.{h,m}'
  # 公开的头文件
  s.public_header_files = 'ZZHNetwork/Header/*.h'
  
  # 解决 pod spec lint 验证不通过
  s.user_target_xcconfig = {
      'GENERATE_INFOPLIST_FILE' => 'YES'
  }
  s.pod_target_xcconfig = {
      'GENERATE_INFOPLIST_FILE' => 'YES'
  }


  # 使用到的资源文件
  # s.resource_bundles = {
  #   'ZZHNetwork' => ['ZZHNetwork/Assets/*.png']
  # }

  
  # 使用的系统库
  s.frameworks = 'Foundation'
  # 使用三方库
  s.dependency 'AFNetworking', '~> 4.0'
  
end
