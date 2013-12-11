require 'date'

date = Date.new(2011, 1, 1)
today = Date.new(2014, 1, 1)

while date < today
    puts "fn.%04d-%02d-%02d" % [date.year, date.month, date.mday]
    date += 1
end


