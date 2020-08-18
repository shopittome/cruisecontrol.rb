# A BuildLogParser understands how to parse Test::Unit and RSpec test errors generated by a build
# run and turn them into a more succinct error representation.
class BuildLogParser

  TEST_ERROR_REGEX = /^\s+\d+\) Error:\n(.*):\n(.*)\n([\s\S]*?)\n\n/

  TEST_NAME_REGEX = /^Failure:\n([^\s]*)/

  #Rails 3 and sorta works with 4.2
  TEST_FAILURE_REGEX = /^Failure:([\S\s]*?)=====/
  MESSAGE_REGEX = /\: ([\s\S]+)/
  STACK_TRACE_REGEX = /\: [\s\S]+\n(.*)\n/

  #Rails 5.2
  TEST_FAILURE2_REGEX = /^Failure:([\S\s]*?bin.*\:\d+)/
  MESSAGE2_REGEX = /([\s\S]+)\[/
  STACK_TRACE2_REGEX = /\[([\s\S]*?)\]\:/

  def initialize(log)
    @log = log
  end

  def errors
    test_errors
  end

  def test_errors
    test_errors = []

    @log.scan(TEST_ERROR_REGEX) do |match|
      test_errors << TestErrorEntry.create_error($1, $2, $3)
    end

    return test_errors
  end

  def summary
    @log.split("\n").grep(/^RUNNING:|tests,.*skips$/)
  end

  def failures
    test_failures
  end

  def test_failures
    test_failures = []

    @log.scan(TEST_FAILURE_REGEX) do |text|
      content = $1

        test_name = content.match(TEST_NAME_REGEX).to_s rescue "TEST_NAME_REGEX"
        message = content.match(MESSAGE_REGEX)[1] rescue "MESSAGE_REGEX"
        stack_trace = content.match(STACK_TRACE_REGEX)[1] rescue "STACK_TRACE_REGEX"

        test_failures << TestErrorEntry.create_failure(test_name, message, stack_trace)

        # Do Nothing, Pattern does not match
    end

    @log.scan(TEST_FAILURE2_REGEX) do |text|
      content = $1

        test_name = text.match(TEST_NAME_REGEX).to_s rescue "TEST_NAME_REGEX"
        message = text.match(MESSAGE2_REGEX)[1] rescue "MESSAGE2_REGEX"
        stack_trace = text.match(STACK_TRACE2_REGEX)[1] rescue "STACK_TRACE2_REGEX"

        test_failures << TestErrorEntry.create_failure(test_name, message, stack_trace)

        # Do Nothing, Pattern does not match
    end

    test_failures
  end

  def failures_and_errors
    failures + errors
  end

end
