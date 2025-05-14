# get user count
# frozen_string_literal: true
namespace :user do
  desc "Print total number of users"
  task count: :environment do
    puts "Total number of users: #{User.count}"
  end
end

# delete posts
namespace :post do
  desc "Delete all posts"
  task delete_all: :environment do
    Post.delete_all
    puts "All posts deleted."
  end
end

# export user csv
namespace :user do
  desc "Export users to CSV"
  task export_csv: :environment do
    require 'csv'
    
    file_path = "tmp/users_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
    CSV.open(file_path, "wb") do |csv|
      csv << ["ID", "Name", "Email", "Created At"]
      User.find_each do |user|
        csv << [user.id, user.first_name,user.last_name, user.email, user.created_at]
      end
    end
    puts "Users exported to #{file_path}"
  end
end

# export post csv
namespace :post do
  desc "Export posts to CSV"
  task export_csv: :environment do
    require 'csv'
    file_path = "tmp/posts.csv"
    CSV.open(file_path,"wb")do |csv|
      csv << ["ID", "Title", "Content", "User ID", "Created At"]
      Post.find_each do |post|
        csv << [post.id, post.title, post.content, post.user_id, post.created_at]
      end 
    end
    puts "Posts exported to #{file_path}"
  end
end


# say welcome email to all users
namespace :user do
  desc "Send welcome email to all users"
  task send_welcome_email: :environment do
    User.find_each do |user|
      UserMailer.welcome_email(user).deliver_now
      puts "Welcome email sent to #{user.email}"
    end
  end  
end

# seeder tasks
namespace :db do
  desc "Seed the database with sample data"
  task seed_users: :environment do
    require 'faker'
    
    10.times do
      User.create(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.email,
        password: 'password'
      )
    end
    
    puts "10 sample users created."
  end
end

# seed posts
namespace :db do
  desc "Seed the database with sample posts"
  task seed_posts: :environment do
    require 'faker'

    10.times do
      Post.create(
        title: Faker::Lorem.sentence(word_count: 3),
        content: Faker::Lorem.paragraphs(number: 2).join("\n"),
        user: User.order("RAND()").first  
      )
    end
    puts "10 sample posts created."
  end
end

# print all users
namespace :user do
  desc "print all users"
  task print_all_users: :environment do
    User.all.each do |user|
      puts "ID: #{user.id}, Name: #{user.first_name} #{user.last_name}, Email: #{user.email}, Created At: #{user.created_at}"
    end
  end
end

# print all posts
namespace :post do
  desc "print all posts"
  task print_all_posts: :environment do
    Post.all.each do |post|
      puts "ID: #{post.id}, Title: #{post.title}, Content: #{post.content}, User ID: #{post.user_id}, Created At: #{post.created_at}"
    end
  end
end

# create user
namespace :user do
  desc "Create a new user"
  task :create, [:first_name, :last_name, :email, :password] => :environment do |t, args|
    user = User.create(
      first_name: args[:first_name],
      last_name:  args[:last_name],
      email:      args[:email],
      password:   args[:password]
    )
    puts "User created successfully: #{user.email}"
  end
end

namespace :post do
  desc "Create a new post"
  task :create, [:title, :content, :user_id] => :environment do |t, args|
    post = Post.create(
      title:   args[:title],
      content: args[:content],
      user_id: args[:user_id]
    )
    puts " Post created successfully: #{post.title} (User ID: #{post.user_id})"
  end
end

# get average posts per user
namespace :stats do
  desc "Calculate average posts per user"
  task average_posts_per_user: :environment do
    user_count = User.count
    post_count = Post.count

    if user_count > 0
      average = post_count.to_f / user_count
      puts "Average posts per user: #{average.round(2)}"
    else
      puts "No users found."
    end
  end
end

