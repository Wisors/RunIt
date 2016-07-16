Pod::Spec.new do |s|
    s.name                  = 'RunIt'
    s.module_name           = 'RunIt'

    s.version               = '0.1.2'

    s.homepage              = 'https://github.com/Wisors/RunIt'
    s.summary               = 'A simple component helps you have only one Singleton.'

    s.author                = { 'Nikishin Alexander' => 'wisorus@gmail.com' }
    s.license               = { :type => 'MIT', :file => 'LICENSE' }
    s.platforms             = { :ios => '8.0' }
    s.ios.deployment_target = '8.0'

    s.source_files          = 'Sources/*.swift'
    s.source                = { :git => 'https://github.com/Wisors/RunIt.git', :tag => s.version }
end
