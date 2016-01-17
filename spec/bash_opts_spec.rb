describe 'bash_opts' do
  let(:path)   { 'lib/bash_opts.sh' }

  def script(definition, input)
    "set -eu; source #{path}; opts #{definition}; opts_eval #{quoted(*input)}"
  end

  def quoted(*input)
    input.flat_map { |str| %("#{str}") }.join(' ')
  end

  shared_examples_for 'sets variables' do |opts, vars|
    vars.each do |name, value|
      include_examples 'sets a variable', opts, name, value
    end
  end

  shared_examples_for 'sets a variable' do |input, name, value|
    it "sets the variable $#{name} to #{value.inspect}" do
      # p [input, name, value, script(definition, input)]
      expect(`bash -c '#{script(definition, input)}; echo $#{name}'`.chomp).to eq value
    end
  end

  shared_examples_for 'sets an array' do |input, name, array|
    let(:input) { input }
    it { expect(`bash -c '#{script(definition, input)}; echo ${#{name}[@]}'`.chomp).to eq array }
  end

  shared_examples_for 'fails to parse' do |input|
    let(:input) { input }
    it { expect(`bash -c '#{script(definition, input)} 2>&1'`.chomp).to eq "Unknown option: #{input}" }
  end

  shared_examples_for 'keeps the given args' do |input, args|
    let(:input) { input }
    it { expect(`bash -c '#{script(definition, input)}; echo ${args[@]}'`.chomp).to eq args }
  end

  describe 'flags' do
    vars = { debug: 'true', verbose: 'true' }

    describe 'long and short defined' do
      let(:definition) { '--[d]ebug --[v]erbose' }
      include_examples 'sets variables', ['--debug', '--verbose'], vars
      include_examples 'sets variables', ['-d', '-v'], vars
    end

    describe 'long defined' do
      let(:definition) { '--debug --verbose' }
      include_examples 'sets variables', ['--debug', '--verbose'], vars
      include_examples 'fails to parse', '-d', vars
    end
  end

  describe 'negated flags' do
    vars = { debug: 'false', verbose: 'false' }

    describe 'not negated' do
      let(:definition) { '--[d]ebug --[v]erbose' }
      include_examples 'sets variables', ['--no-debug', '--no-verbose'], vars
    end

    describe 'negated' do
      let(:definition) { '--no-debug --no-verbose' }
      include_examples 'sets variables', ['--no-debug', '--no-verbose'], vars
    end
  end

  describe 'vars (using =)' do
    vars = { file: './file.sh', name: 'foo' }

    describe 'long and short defined' do
      let(:definition) { '--[f]ile= --[n]ame=' }
      include_examples 'sets variables', ['--file=./file.sh', '--name=foo'], vars
      include_examples 'sets variables', ['-f=./file.sh', '-n=foo'], vars
    end

    describe 'long defined' do
      let(:definition) { '--file= --name=' }
      include_examples 'sets variables', ['--file=./file.sh', '--name=foo'], vars
      include_examples 'fails to parse', '-f=./file.sh'
    end

    describe 'with spaces' do
      let(:definition) { '--file=' }
      include_examples 'sets variables', ['--file', './file with spaces.sh'], file: './file with spaces.sh'
    end
  end

  describe 'vars (not using =)' do
    vars = { file: './file.sh', name: 'foo' }

    describe 'long and short defined' do
      let(:definition) { '--[f]ile= --[n]ame=' }
      include_examples 'sets variables', ['--file', './file.sh', '--name', 'foo'], vars
      include_examples 'sets variables', ['-f', './file.sh', '-n', 'foo'], vars
    end

    describe 'long defined' do
      let(:definition) { '--file= --name=' }
      include_examples 'sets variables', ['--file', './file.sh', '--name', 'foo'], vars
      include_examples 'fails to parse', '-f ./file.sh'
    end
  end

  describe 'arrays (using =)' do
    let(:definition) { '--names[]=' }
    include_examples 'sets an array', ['--name=foo', '--name=bar'], 'names', 'foo bar'
  end

  describe 'arrays (not using =)' do
    let(:definition) { '--names[]=' }
    include_examples 'sets an array', ['--name', 'foo', '--name', 'bar'], 'names', 'foo bar'
  end

  describe 'args' do
    let(:definition) { '--debug --name=' }

    describe 'quoted' do
      include_examples 'keeps the given args', ['"foo"', '--debug'], 'foo'
    end

    describe 'given at the beginning' do
      include_examples 'keeps the given args', ['--name', 'name', 'foo', 'bar', '--debug'], 'foo bar'
    end

    describe 'given in the middle' do
      include_examples 'keeps the given args', ['--name', 'name', 'foo', 'bar', '--debug'], 'foo bar'
    end

    describe 'given at the end' do
      include_examples 'keeps the given args', ['--name', 'name', '--debug', 'foo', 'bar'], 'foo bar'
    end

    describe 'given all over the place' do
      include_examples 'keeps the given args', ['foo', '--name', 'name', 'bar', '--debug', 'baz'], 'foo bar baz'
    end
  end
end
