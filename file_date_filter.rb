require 'date'

class Integer
    # Adding "3 days, 4 months, etc."
    def method_missing(meth, *args, &block)
        method = meth.to_sym
        unless [:days, :weeks, :calendar_weeks, :months, :calendar_months, :years, :calendar_years].include?(method)
            raise "Unknown date range type: #{method}"
        end
        return DateRangeRule.new(method, self.to_i)
    end
end

module FileDateFilter
    public

    attr_accessor :today
    @today = Date.today

    attr_accessor :logger

    def log(*args)
        if FileDateFilter.logger
            args.each do |arg|
                FileDateFilter.logger.write arg
            end
            puts
        end
    end

    class DateRange
        def initialize(date_range_rule, base_date)
            @from, @to = date_range_rule.apply(base_date)
        end

        def contains?(date)
            res = @from <= date && date <= @to
            log "# contains?: #{date} bounds=(#{@from}, #{@to}) = #{res}"
            res
        end
    end

    class DateRangeRule
        def initialize(kind, value)
            @kind = kind
            @value = value
        end

        def apply(base_date=FileDateFilter.today)
            case @kind
            when :days
                from = base_date - (@value - 1)
            when :weeks
                from = base_date - (7 * @value) 
            when :calendar_weeks
                from = (base_date - base_date.wday) - (7 * (@value - 1))
            when :months
                from = base_date << @value
            when :calendar_months
                from = (base_date - base_date.mday)  << (@value - 1)
            when :years
                from = base_date << (@value * 12)
            when :calendar_years
                from = (base_date - base_date.yday) << (12 * (@value - 1))
            else
                raise "Unknown data range: #{@kind}"
            end

            [from, base_date]
        end
    end

    class FileInfo
        def initialize(date, name=nil) 
            @date = date
            @name = name
            @keep = false
        end

        def name()
            @name
        end

        def date()
            @date
        end

        def keep=(flag) 
            @keep = flag
        end

        def keep()
            @keep
        end

        def str()
        "#{name} #{keep}"
        end
    end

    class Filter
        def initialize(files) 
            @files = files.sort_by {|f| f.date}
            reset
        end

        def files
            @files
        end

        def within(date_range_rule)
            date_range = DateRange.new(date_range_rule, FileDateFilter.today)
            @active_files = @active_files.flatten.select do |f|
                date_range.contains?(f.date) 
            end
            self
        end

        def reset
            @active_files = [@files]
            log "# RULE"
            log "# Active size: #{@active_files.flatten.length}"
            self
        end

        def rule()
            reset
        end

        def every_month()
            @active_files = Filter.group_by(:month, @active_files.flatten)
            self
        end

        def every_week()
            @active_files = Filter.group_by(:week, @active_files.flatten)
            self
        end

        def every_day()
            @active_files = Filter.group_by(:day, @active_files.flatten)
            self
        end

        def keep_newest()
            @active_files.each do |file_group|
                if file_group.length > 0 
                    file_group[-1].keep = true
                    log "# #{file_group[-1].date} keep_newest"
                end
            end
            return self
        end

        def keep_all()
            log "# active size: #{@active_files.flatten.length}"
            @active_files.flatten.map do |f|
                f.keep = true
                log "keeping #{f.date}"
            end
            self
        end

        def days(count)
            return self
        end

        def weeks(count) 
            return self
        end

        def months(count)
            return self
        end

        def years(count)
            return self
        end

        def each(&block) 
            if block_given?
                @files.each do |f|
                    block.call(f)
                end
            end
        end

        def print_files(keep) 
            @files.each.select{|f| f.keep == keep}.each do |f|
                puts f.name
            end
        end

        private
        def interval() 
            return self
        end

        def self.day_key(date)
            date.ld
        end

        def self.week_key(date)
            # First day - Sunday
            (date.ld + 4) / 7
        end

        def self.month_key(date)
            date.year * 12 + date.month
        end

        def self.year_key(date)
            date.year
        end

        def self.group_by(key, files) 
            case key 
            when :day 
                files.group_by {|r| Filter.day_key(r.date)}.values
            when :week
                files.group_by {|r| Filter.week_key(r.date)}.values
            when :month
                files.group_by {|r| Filter.month_key(r.date)}.values
            when :year
                files.group_by {|r| Filter.year_key(r.date)}.values
            else
                raise "Internal error: Cannot group by key #{key}"
            end
        end

        def self.parse_date(date_string)
            log "# Parsing date #{date_string}"
            re = /(\d{4})-(\d{2})-(\d{2})/
            match = re.match(date_string)
            unless match
                raise "Cannot parse file name as date: #{date_string}"
            end
            log "match: #{match[1]} #{match[2]} #{match[3]}"
            return Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
        end

        def self.from_file_list(file_list) 
            file_infos = file_list.map do |name|
                date = Filter.parse_date(name)
                FileInfo.new(date, name)
            end
            Filter.new(file_infos)
        end

        def self.from_stream(stream)
            files = stream.readlines.map{|f| f.strip}
            Filter.from_file_list(files)
        end

        def self.from_stdin
            return Filter.from_stream($stdin)
        end
    end
end

