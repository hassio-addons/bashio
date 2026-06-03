# Coverage configuration used by bashcov when running the Bats test suite.
require "stringio"
require "simplecov-cobertura"

SimpleCov.start do
  command_name "bats"
  add_filter %r{/tests/}
  formatter SimpleCov::Formatter::CoberturaFormatter
end
