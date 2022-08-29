Oj.default_options = { mode: :custom, time_format: :ruby, use_to_json: true }
Oj.optimize_rails()

Blueprinter.configure do |config|
  config.generator = Oj
end
