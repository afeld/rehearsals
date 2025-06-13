require "icalendar"
require "csv"

START_FROM = DateTime.new(2024, 7, 28)
MY_EMAIL = "aidan.feldman@gmail.com"
CAL_PATH = File.expand_path("~/Downloads/Personal_#{MY_EMAIL}.ics")

def relevant?(event)
  event.summary.include? "Artichoke" or
    event.summary.include? "ADC" or
    # event organizer empty in some cases
    event.organizer&.to.eql? "artichokedancecompany@gmail.com"
end

def attending?(event)
  me = event.attendee.find { |attendee| attendee.to.eql? MY_EMAIL }

  if !me
    # assuming it was an event I created
    return true
  end

  rsvps = me.ical_params["partstat"]

  # sanity checking
  if rsvps != ["ACCEPTED"] && rsvps != ["DECLINED"]
    raise "RSVP: #{rsvps}"
  end

  rsvps.first == "ACCEPTED"
end

def eligible?(event)
  event.dtstart >= START_FROM and
    event.dtstart < Time.now and
    relevant?(event) and
    attending?(event)
end

def duration_in_hours(event)
  duration_in_secs = event.dtend.to_time - event.dtstart.to_time
  duration_in_secs / 60 / 60
end

def format_time(time)
  time.in_time_zone("America/New_York").strftime("%m/%d/%Y %H:%M:%S")
end

# gets set to US-ASCII when run through rdbg
Encoding.default_external = "UTF-8"

cal_file = File.open(CAL_PATH)
cals = Icalendar::Calendar.parse(cal_file)
cal = cals.first

CSV.open("rehearsals.csv", "w") do |csv|
  csv << ["Name", "Location", "Start", "End", "Hours"]

  events = cal.events.sort_by(&:dtstart)
  events.each do |event|
    if eligible?(event)
      row = [
        event.summary,
        event.location,
        format_time(event.dtstart),
        format_time(event.dtend),
        "%.1f" % duration_in_hours(event)
      ]
      puts row
      csv << row
    end
  end
end
