expected=test.expected
out=/tmp/test.out

all:
	ruby file_generator.rb | ruby test_filter.rb > ${out}
	cmp ${out} ${expected} || false

