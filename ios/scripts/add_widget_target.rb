# Adds the FindMeWidget extension to Runner.xcodeproj in CI, because there is no Mac
# to do it in Xcode. Run from ios/: `ruby scripts/add_widget_target.rb`. Not committed back: CI changes its own copy.
require 'xcodeproj'

project = Xcodeproj::Project.open('Runner.xcodeproj')
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'FindMeWidget already added' if project.targets.any? { |t| t.name == 'FindMeWidget' }

widget = project.new_target(:app_extension, 'FindMeWidget', :ios, '15.0')
group = project.main_group.new_group('FindMeWidget', 'FindMeWidget')
widget.add_file_references([group.new_file('FindMeWidget.swift')])
group.new_file('Info.plist')

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'app.findme.mobile.FindMeWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'FindMeWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
end
# Flutter builds Release and Profile; new_target only makes Debug and Release.
unless widget.build_configurations.any? { |c| c.name == 'Profile' }
  profile = widget.add_build_configuration('Profile', :release)
  profile.build_settings.merge!(widget.build_configurations.find { |c| c.name == 'Release' }.build_settings)
end

runner.add_dependency(widget)
embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed.name = 'Embed App Extensions'
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# Before Flutter's "Thin Binary" script, or Xcode reports a dependency cycle.
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' } || runner.build_phases.size
runner.build_phases.insert(thin, embed)

project.save
puts 'FindMeWidget added'
