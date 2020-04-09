
Pod::Spec.new do |spec|


  spec.name         = "KnobControlDDzz"
  spec.version      = "1.1.0"
  spec.summary      = "KnobControlDDzz - desc"

  spec.description  = "<<-DESC
                        here is description.
                        DESC."

  spec.homepage     = "https://github.com/JasonSparrow/KnobControlDDzz"

  spec.license      = "MIT"


  spec.author             = { "王腾飞" => "18937192819@163.com" }


  spec.platform     = :ios, "12.0"



    spec.source       = { :git => "https://github.com/JasonSparrow/KnobControlDDzz.git", :tag => spec.version }


  spec.source_files  = "KnobControl"
  spec.exclude_files = "Classes/Exclude"


 spec.requires_arc = true

    spec.swift_version = "5.0"

end
