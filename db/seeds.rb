if Rails.env.production? && ENV["ALLOW_PRODUCTION_SEEDS"] != "true"
  abort "Refusing to run seed data in production. Set ALLOW_PRODUCTION_SEEDS=true only for an intentional one-time bootstrap."
end

seed_password = ENV.fetch("CONFVOICE_SEED_PASSWORD", "confvoice-local-password")
if Rails.env.production? && (seed_password.blank? || seed_password == "confvoice-local-password")
  abort "Set CONFVOICE_SEED_PASSWORD to a private password before running production seeds."
end

puts "Creating seed data..."

seed_user = lambda do |email_address:, name:, role:|
  user = User.find_or_initialize_by(email_address: email_address)
  if user.new_record?
    user.password = seed_password
    user.password_confirmation = seed_password
    user.role = role
  end
  user.name = name
  user.save!
  user
end

admin = seed_user.call(email_address: "admin@example.com", name: "Administrator", role: :admin)
organizer = seed_user.call(email_address: "organizer@example.com", name: "Alex Morgan", role: :organizer)
speaker = seed_user.call(email_address: "speaker@example.com", name: "Jamie Lee", role: :audience)

conference = Conference.find_by(slug: "rubykaigi2026") || Conference.new
conference.assign_attributes(
  slug: "rubykaigi2026",
  name: "RubyKaigi 2026",
  description: "Japan's premier Ruby conference",
  venue: "Tokyo International Forum",
  starts_on: Date.new(2026, 9, 10),
  ends_on: Date.new(2026, 9, 12),
  published: true
)
conference.save!

ConferenceMembership.find_or_create_by!(user: organizer, conference: conference) do |membership|
  membership.role = :organizer
end

ConferenceMembership.find_or_create_by!(user: admin, conference: conference) do |membership|
  membership.role = :organizer
end

ConferenceMembership.find_or_create_by!(user: speaker, conference: conference) do |membership|
  membership.role = :speaker
end

sessions_data = [
  { title: "Keynote: The Future of Ruby", slug: "keynote-ruby", speaker: "Yukihiro Matsumoto", room: "Hall A", hour: 10 },
  { title: "What's New in Rails 8.1", slug: "rails-8-1", speaker: "DHH", room: "Hall A", hour: 11 },
  { title: "Practical Hotwire", slug: "hotwire", speaker: "Jamie Lee", room: "Hall B", hour: 13 },
  { title: "Performance Tuning in Practice", slug: "performance-tuning", speaker: "Hana Tanaka", room: "Hall B", hour: 14 },
  { title: "A Practical Guide to Test-Driven Development", slug: "test-driven-development", speaker: "Jordan Sato", room: "Hall A", hour: 15 }
]

sessions = sessions_data.map do |data|
  session = Session.find_or_initialize_by(conference: conference, slug: data[:slug])
  session.title = data[:title]
  session.speaker_name = data[:speaker]
  session.speaker_user = speaker if data[:slug] == "hotwire"
  session.room = data[:room]
  session.starts_at = Time.zone.local(2026, 9, 10, data[:hour], 0)
  session.ends_at = Time.zone.local(2026, 9, 10, data[:hour], 50)
  session.feedback_open = true
  session.save!
  session
end

sample_bodies = [
  "Now I can picture how to apply this at work.",
  "The pacing was great and the key points were easy to follow.",
  "I would love to see a few more code examples.",
  "I am excited to try this tomorrow."
]

sessions.each_with_index do |session, session_index|
  3.times do |index|
    feedback = Feedback.find_or_initialize_by(
      session: session,
      respondent_token: "seed-#{session_index}-#{index}"
    )
    feedback.respondent_name = "Attendee #{index + 1}"
    feedback.rating = 3 + ((session_index + index) % 3)
    feedback.body = sample_bodies[(session_index + index) % sample_bodies.length]
    feedback.save!
  end
  Reaction.kinds.keys.each_with_index do |kind, index|
    Reaction.find_or_create_by!(
      session: session,
      kind: kind,
      respondent_token: "seed-reaction-#{session_index}-#{index}"
    )
  end
  session.speaker_invites.create! if session_index.zero? && session.speaker_invites.none?
  session.update_stats!
end

puts "Seed data created!"
puts "  Admin:     admin@example.com"
puts "  Organizer: organizer@example.com"
puts "  Speaker:   speaker@example.com"
puts "  Conference: #{conference.name} (#{conference.sessions.count} sessions)"
