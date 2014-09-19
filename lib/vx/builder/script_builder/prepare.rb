require 'vx/common'

module Vx
  module Builder
    class ScriptBuilder

      Prepare = Struct.new(:app) do

        include Common::Helper::TraceShCommand
        include Common::Helper::UploadShCommand

        def call(env)
          name         = env.task.name
          deploy_key   = env.task.deploy_key

          repo_path    = "${VX_ROOT}/code/#{name}"
          data_path    = "${VX_ROOT}/data/#{name}"
          key_file     = env.organization_key ? "${VX_ROOT}/.ssh/id_rsa" : "#{data_path}/key"

          git_ssh_file = "#{data_path}/git_ssh"

          sha          = env.task.sha
          scm          = build_scm(env, sha, repo_path)
          git_ssh      = scm.git_ssh_content(deploy_key && "#{key_file}")

          env.init.tap do |i|
            i << 'export VX_ROOT=$(pwd)'
            i << 'export PATH=$VX_ROOT/bin:$PATH'

            i << "mkdir -p $VX_ROOT/bin"
            i << "mkdir -p #{data_path}"
            i << "mkdir -p #{repo_path}"

            %w{ vx_parallel_rspec vx_parallel_spinach }.each do |bin|
              src = File.expand_path("../../../../../bin/#{bin}", __FILE__)
              dst = "$(pwd)/bin/#{bin.sub("vx_", "")}"
              i << upload_sh_command(dst, File.read(src))
              i << "chmod 0750 #{dst}"
            end

            if deploy_key
              i << upload_sh_command(key_file, deploy_key)
              i << "chmod 0600 #{key_file}"
              i << "export VX_PRIVATE_KEY=#{key_file}"
            end

            i << upload_sh_command(git_ssh_file, git_ssh)
            i << "chmod 0750 #{git_ssh_file}"

            i << "export GIT_SSH=#{git_ssh_file}"
            i << "#{scm.fetch_cmd} || exit 1"
            i << "unset GIT_SSH"

            i << 'echo "starting SSH Agent"'
            i << 'eval "$(ssh-agent)" > /dev/null'
            i << "ssh-add $VX_PRIVATE_KEY 2> /dev/null"

            i << "cd #{repo_path}"

            # At BeBanjo we're not using vxvm
            #i << 'echo "download latest version of vxvm"'
            #i << "curl --tcp-nodelay --retry 3 --fail --silent --show-error -o $VX_ROOT/bin/vxvm https://raw.githubusercontent.com/vexor/vx-packages/master/vxvm"
            #i << "chmod +x $VX_ROOT/bin/vxvm"
          end

          env.after_script_init.tap do |i|
            i << 'export VX_ROOT=$(pwd)'
            i << "test -d #{repo_path} || exit 1"
            i << "cd #{repo_path}"
          end

          app.call env
        end

        private

          def build_scm(env, sha, path)
            Common::Git.new(env.task.src,
                         sha,
                         path,
                         branch: branch_name(env),
                         pull_request_id: env.task.pull_request_id)
          end

          def branch_name(env)
            b = env.task && env.task.branch
            if b && b != 'HEAD'
              b
            end
          end

      end
    end
  end
end
