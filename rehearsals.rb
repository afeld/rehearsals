require "csv"
require "icalendar"
require "icalendar/recurrence"

ZONE = TZInfo::Timezone.get("America/New_York")
START_FROM = Time.new(2025, 8, 16, in: ZONE)
MY_EMAIL = "aidan.feldman@gmail.com"
CAL_PATH = File.expand_path("~/Downloads/aidan.feldman@gmail.com.ical/Personal_#{MY_EMAIL}.ics")

def relevant?(event)
  event.summary.include? "Artichoke" or
    event.summary.include? "ADC" or
    # event organizer empty in some cases
    event.organizer&.to.eql? "artichokedancecompany@gmail.com"
end

def attending?(event)
  me = event.attendee.find do |attendee|
    email = attendee.to.to_s.downcase
    email = email.sub(/\Amailto:/, "")
    email == MY_EMAIL.downcase
  end

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
  start_time = event.start_time

  start_time >= START_FROM and
    start_time <= Time.now and
    relevant?(event) and
    attending?(event)
end

def duration_in_hours(event)
  duration_in_secs = event.dtend.to_time - event.dtstart.to_time
  duration_in_secs / 60 / 60
end

def format_time(time)
  time.getlocal(ZONE).strftime("%m/%d/%Y %H:%M:%S")
end

# gets set to US-ASCII when run through rdbg
Encoding.default_external = "UTF-8"

cal_file = File.open(CAL_PATH)
cals = Icalendar::Calendar.parse(cal_file)
cal = cals.first

CSV.open("rehearsals.csv", "w") do |csv|
  csv << ["Name", "Location", "Start", "End", "Hours"]

  events = cal.events.sort_by(&:start_time)
  events = events.select { |e| eligible?(e) }

  events.each do |event|
    occurrences = event.occurrences_between(event.start_time, Time.now)
    occurrences.each do |occurrence|
      row = [
        event.summary,
        event.location,
        format_time(occurrence.start_time),
        format_time(occurrence.end_time),
        "%.2f" % duration_in_hours(event)
      ]
      puts row
      csv << row
    end
  end
end
