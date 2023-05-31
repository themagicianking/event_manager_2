require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def clean_phone_number(phone)
  phone = phone.delete("^0-9")
  if phone.length == 11 && phone[0] == 1
    phone[1..10]
  elsif phone.length < 10 || phone.length >= 11
    "No phone number provided."
  else
    phone
  end
end

def get_hour(date)
  Time.strptime(date, "%m/%d/%Y %H:%M").hour
end

def get_weekday(date)
  Date::DAYNAMES[Time.strptime(date, "%m/%d/%Y %H:%M").wday]
end

def get_peak_hours(hours)
  peak = hours.max_by { |i| hours.count(i)}
  hours.delete(peak)
  peak_two = hours.max_by { |i| hours.count(i)}
  puts "The peak hours for registration: #{peak}:00 and #{peak_two}:00."
end

def get_peak_weekdays(days)
  peak = days.max_by { |i| days.count(i)}
  days.delete(peak)
  peak_two = days.max_by { |i| days.count(i)}
  puts "The peak days for registration: #{peak} and #{peak_two}."
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized."

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

peak_hours = []
peak_weekdays = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  hour = get_hour(row[:regdate])
  weekday = get_weekday(row[:regdate])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
  peak_hours.push(hour)
  peak_weekdays.push(weekday)
end

get_peak_hours(peak_hours)
get_peak_weekdays(peak_weekdays)