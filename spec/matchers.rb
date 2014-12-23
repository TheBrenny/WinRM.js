require 'rspec/expectations'

module WinRMSpecs
  def self.stdout(output)
    output[:data].collect do |i|
      i[:stdout]
    end.join('\r\n').gsub(/(\\r\\n)+$/, '')
  end

  def self.stderr(output)
    output[:data].collect do |i|
      i[:stderr]
    end.join('\r\n').gsub(/(\\r\\n)+$/, '')
  end
end

RSpec::Matchers.define :have_stdout_match do |expected_stdout|
  match do |actual_output|
    expected_stdout.match(WinRMSpecs.stdout(actual_output)) != nil
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stdout(actual_output)}' would match #{expected_stdout}"
  end
end

RSpec::Matchers.define :have_stderr_match do |expected_stderr|
  match do |actual_output|
    expected_stderr.match(WinRMSpecs.stderr(actual_output)) != nil
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stderr(actual_output)}' would match #{expected_stderr}"
  end
end

RSpec::Matchers.define :have_no_stdout do
  match do |actual_output|
    stdout = WinRMSpecs.stdout(actual_output)
    stdout == '\r\n' || stdout == ''
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stdout(actual_output)}' would have no stdout"
  end
end

RSpec::Matchers.define :have_no_stderr do
  match do |actual_output|
    stderr = WinRMSpecs.stderr(actual_output)
    stderr == '\r\n' || stderr == ''
  end
  failure_message do |actual_output|
    "expected that '#{WinRMSpecs.stderr(actual_output)}' would have no stderr"
  end
end

RSpec::Matchers.define :have_exit_code do |expected_exit_code|
  match do |actual_output|
    expected_exit_code == actual_output[:exitcode]
  end
  failure_message do |actual_output|
    "expected exit code #{expected_exit_code}, but got #{actual_output[:exitcode]}"
  end
end

RSpec::Matchers.define :be_a_uid do
  match do |actual|
    # WinRM1.1 returns uuid's prefixed with 'uuid:' where as later versions do not
    actual != nil && actual.match(/^(uuid:)*\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/)
  end
  failure_message do |actual|
    "expected a uid, but got '#{actual}'"
  end
end

RSpec::Matchers.define :have_created do |remote_file|
  match do |file_manager|
    if @expected_content
      downloaded_file = Tempfile.new('downloaded')
      downloaded_file.close()

      subject.download(remote_file, downloaded_file.path)
      @actual_content = File.read(downloaded_file.path)
      downloaded_file.delete()
      
      result = file_manager.exists?(remote_file) && \
        @actual_content == @expected_content
    else
      file_manager.exists?(remote_file)
    end
  end
  chain :with_content do |expected_content|
    expected_content = File.read(expected_content) if File.file?(expected_content)
    @expected_content = expected_content
  end
  failure_message do |file_manager|
    if @expected_content
      <<-EOH
Expected file '#{remote_file}' to exist with content:

#{@expected_content}

but instead got content:

#{@actual_content}
      EOH
    else
      "Expected file '#{remote_file}' to exist"
    end
  end
end

RSpec::Matchers.define :contain_zip_entries do |zip_entries|
  match do |temp_zip_file|
    zip_entries = [zip_entries] if zip_entries.is_a? String
    zip_file = Zip::File.open(temp_zip_file.path)
    @missing_entries = []
    zip_entries.each do |entry|
      @missing_entries << entry unless zip_file.find_entry(entry)
    end
    @missing_entries.empty?
  end
  failure_message do |temp_zip_file|
    "Expected #{temp_zip_file.path} to contain zip entries: #{@missing_entries}"
  end
end