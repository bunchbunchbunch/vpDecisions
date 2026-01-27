#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'VideoPokerTrainer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'VideoPokerTrainer' }

# Helper method to find or create a group with path
def find_or_create_group_with_path(parent_group, name, path_name = nil)
  existing = parent_group.children.find { |g| g.display_name == name }
  if existing
    return existing
  end

  # Create new group with path attribute
  new_group = parent_group.new_group(name, path_name || name)
  puts "Created group: #{name} with path: #{path_name || name}"
  new_group
end

# Get the main group (VideoPokerTrainer folder)
main_group = project.main_group.children.find { |g| g.display_name == 'VideoPokerTrainer' }

unless main_group
  puts "ERROR: Could not find VideoPokerTrainer group"
  exit 1
end

puts "Found main group: #{main_group.display_name}"

# Find existing groups
models_group = main_group.children.find { |g| g.display_name == 'Models' }
services_group = main_group.children.find { |g| g.display_name == 'Services' }
viewmodels_group = main_group.children.find { |g| g.display_name == 'ViewModels' }
views_group = main_group.children.find { |g| g.display_name == 'Views' }
resources_group = main_group.children.find { |g| g.display_name == 'Resources' }

puts "Models group: #{models_group ? 'Found' : 'Not found'}"
puts "Services group: #{services_group ? 'Found' : 'Not found'}"
puts "ViewModels group: #{viewmodels_group ? 'Found' : 'Not found'}"
puts "Views group: #{views_group ? 'Found' : 'Not found'}"
puts "Resources group: #{resources_group ? 'Found' : 'Not found'}"

# Create Resources group if it doesn't exist
unless resources_group
  resources_group = main_group.new_group('Resources', 'Resources')
end

# Helper to add file if not already present
def add_file_to_group(group, file_name, target, is_resource = false)
  existing = group.children.find { |f| f.respond_to?(:path) && f.path == file_name }
  return existing if existing

  file_ref = group.new_file(file_name)

  if is_resource
    target.resources_build_phase.add_file_reference(file_ref)
  else
    target.source_build_phase.add_file_reference(file_ref)
  end

  puts "Added: #{file_name}"
  file_ref
end

# Add Model files
puts "\n=== Adding Model files ==="
model_files = ['Lesson.swift', 'Drill.swift', 'ReviewItem.swift']
model_files.each do |file|
  full_path = "VideoPokerTrainer/Models/#{file}"
  add_file_to_group(models_group, file, target) if File.exist?(full_path)
end

# Add Service files
puts "\n=== Adding Service files ==="
service_files = ['TrainingService.swift', 'ReviewQueueService.swift']
service_files.each do |file|
  full_path = "VideoPokerTrainer/Services/#{file}"
  add_file_to_group(services_group, file, target) if File.exist?(full_path)
end

# Add ViewModel files
puts "\n=== Adding ViewModel files ==="
viewmodel_files = ['TrainingHubViewModel.swift', 'LessonViewModel.swift', 'DrillViewModel.swift', 'ReviewQueueViewModel.swift']
viewmodel_files.each do |file|
  full_path = "VideoPokerTrainer/ViewModels/#{file}"
  add_file_to_group(viewmodels_group, file, target) if File.exist?(full_path)
end

# Add Training Views
puts "\n=== Adding Training Views ==="

# Create Training group under Views with path
training_group = find_or_create_group_with_path(views_group, 'Training', 'Training')

# Add TrainingHubView
add_file_to_group(training_group, 'TrainingHubView.swift', target) if File.exist?('VideoPokerTrainer/Views/Training/TrainingHubView.swift')

# Create and populate Lessons group with path
lessons_group = find_or_create_group_with_path(training_group, 'Lessons', 'Lessons')
lesson_views = ['LessonDetailView.swift', 'LessonQuizView.swift', 'LessonCompleteView.swift']
lesson_views.each do |file|
  full_path = "VideoPokerTrainer/Views/Training/Lessons/#{file}"
  add_file_to_group(lessons_group, file, target) if File.exist?(full_path)
end

# Create and populate Drills group with path
drills_group = find_or_create_group_with_path(training_group, 'Drills', 'Drills')
drill_views = ['DrillPlayView.swift', 'DrillCompleteView.swift']
drill_views.each do |file|
  full_path = "VideoPokerTrainer/Views/Training/Drills/#{file}"
  add_file_to_group(drills_group, file, target) if File.exist?(full_path)
end

# Create and populate Review group with path
review_group = find_or_create_group_with_path(training_group, 'Review', 'Review')
add_file_to_group(review_group, 'ReviewQueueView.swift', target) if File.exist?('VideoPokerTrainer/Views/Training/Review/ReviewQueueView.swift')

# Add Lesson JSON resources
puts "\n=== Adding Lesson JSON files ==="
lessons_res_group = find_or_create_group_with_path(resources_group, 'Lessons', 'Lessons')
lesson_jsons = ['job-made-hands.json', 'job-high-cards.json', 'job-penalty-cards.json']
lesson_jsons.each do |file|
  full_path = "VideoPokerTrainer/Resources/Lessons/#{file}"
  add_file_to_group(lessons_res_group, file, target, true) if File.exist?(full_path)
end

# Save the project
project.save
puts "\n=== Project saved successfully ==="
