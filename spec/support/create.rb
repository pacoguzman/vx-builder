require 'ostruct'

def create(name, options = {})
  case name
  when :message
    Vx::Message::PerformBuild.test_message

  when :task
    msg = create(:message)
    Vx::Builder::Task.new(
      'name',
      msg.src,
      msg.sha,
      deploy_key: msg.deploy_key,
      branch:     msg.branch,
      cache_url_prefix: "http://example.com/"
    )

  when :source
    Vx::Builder::Source.from_yaml(fixture("travis.yml"))

  when :env
    OpenStruct.new(
      init:           [],
      before_install: [],
      install:        [],
      announce:       [],
      before_script:  [],
      script:         [],
      after_script:   [],
      source:         create(:source),
      task:           create(:task),
      cache_key:      [],
      cached_directories: []
    )

  when :command_from_env
    env = options[:env]
    a = ["set -e"]
    a += env.init
    a.join("\n")
  end
end
