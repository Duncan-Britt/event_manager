require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
   pn = phone_number.tr('^0123456789', '')
   if pn.length == 10
     pn
   elsif pn.length == 11
     if pn.chars[0] == '1'
       pn[0] = ''
       pn
     end
   end
end

def clean_reg_time(date_and_time)
  hour =  DateTime.strptime(date_and_time, '%m/%d/%Y %H:%M').hour
end

def clean_reg_days(date_and_time)
  day =  DateTime.strptime(date_and_time, '%m/%d/%Y %H:%M').wday
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hours = []
registration_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  registration_hours.push(clean_reg_time(row[:regdate]))
  registration_days.push(clean_reg_days(row[:regdate]))
  phone_number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  # puts "#{phone_number}"
  save_thank_you_letter(id,form_letter)
end

def get_mode(array)
  mode = array.uniq
                    .map { |e| [e, array.count(e)]}
                    .sort_by {|_,cnt| -cnt}
  mode = mode.take_while {|_,cnt| cnt == mode.first.last}
   .map(&:first)
end

def convert_week_day(arr)
  b = []
  arr.each do |e|
    case e
    when 0
      b.push("Sunday")
    when 1
      b.push("Monday")
    when 2
      b.push("Tuesday")
    when 3
      b.push("Wednesday")
    when 4
      b.push("Thursday")
    when 5
      b.push("Friday")
    when 6
      b.push("Saturday")
    end
  end
  return b.join('')
end

puts "The best hours are #{get_mode(registration_hours)}"
p registration_days
puts "The best day(s) of the week is/are #{convert_week_day(get_mode(registration_days))}"
