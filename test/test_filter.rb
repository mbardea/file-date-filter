require '../file_date_filter'
include FileDateFilter

#FileDateFilter.logger = STDERR
FileDateFilter.today = Date.new(2014, 1, 1)

filter = FileDateFilter::Filter.from_stdin

filter
    .rule
        .every_month.keep_newest
    .rule
         .every_week.keep_newest
    .rule
        .within(2.calendar_months).every_day.keep_newest
    .rule
        .within(2.calendar_weeks).keep_all

puts "# included:"
filter.print_files true
puts
puts "# excluded:"
filter.print_files false
