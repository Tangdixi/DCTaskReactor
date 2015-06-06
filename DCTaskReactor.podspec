Pod::Spec.new do |s|

  s.name         = "DCTaskReactor"
  s.version      = "1.0"
  s.summary      = "Extention for NSOperationQueue"

  s.description  = <<-DESC
			DCTaskReactor extent the NSOperationQueue, including a FIFO queue and LIFO queue, make it more simple for using. 
                   DESC

  s.homepage     = "https://github.com/Tangdixi/DCTaskReactor" 

  s.license      = { 
	:type => 'MIT', 
	:text => 'The DCTaskReactor use the MIT license' 
  }

  s.author             = { "Tangdixi" => "Tangdixi@gmail.com" }

  s.platform     = :ios, '7.0'

  s.source       = { 
	:git => "https://github.com/Tangdixi/DCTaskReactor.git", 
	:tag => "1.0"
  }

  s.source_files  = 'DCTaskReactor/*.{h,m}', 'DCTaskReactor/Category/*.{h,m}'

  s.frameworks = 'Foundation','UIKit'

  s.requires_arc = true

end
