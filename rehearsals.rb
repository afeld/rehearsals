# 1. `gem install icalendar`
# 2. Get the "Secret adddress in iCal format" from Google Calendar: https://support.google.com/calendar/answer/37083#link
# 3. Open that URL in a browser to download the .ics file
# 3. Modify the constants below
# 4. Run `ruby rehearsals.rb`

require "icalendar"
require "csv"

START_FROM = DateTime.new(2023, 4, 25)
CAL_PATH = File.expand_path("~/Downloads/basic.ics")

def format_time(time)
  time.in_time_zone("America/New_York").strftime("%m/%d/%Y %H:%M:%S")
end

# # Open a file or pass a string to the parser
cal_file = File.open(CAL_PATH)

# Parser returns an array of calendars because a single file
# can have multiple calendars.
cals = Icalendar::Calendar.parse(cal_file)
cal = cals.first


CSV.open("rehearsals.csv", "w") do |csv|
  csv << ["Name", "Location", "Start", "End"]

  # Now you can access the cal object in just the same way I created it
  cal.events.each do |event|
    if event.dtstart >= START_FROM and event.dtstart < Time.now and event.summary.include? "Artichoke"
      row = [
        event.summary,
        event.location,
        format_time(event.dtstart),
        format_time(event.dtend)
      ]
      puts row
      csv << row
    end
  end
end
