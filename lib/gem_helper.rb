require 'bundler/gem_helper'

module LoveOS
  class GemHelper < Bundler::GemHelper

    def install
      built_gem_path = nil

      namespace :gem do
        desc "Build #{name}-#{version}.gem into ./pkg/"
        task 'build' do
          built_gem_path = build_gem
        end

        desc "Install #{name}-#{version}.gem locally"
        task "install" do
          install_gem
        end

        desc "Release #{name}-#{version}.gem on #{dawanda}"
        task :release do
          release_gem
        end
      end
    end

    protected

    def dawanda
      "dist.dawanda.in"
    end

    def dawanda_user
      "deploy"
    end

    def release_gem(built_gem_path = nil)
      guard_clean
      built_gem_path ||= build_gem

      unless retag?
        if respond_to?(:guard_already_tagged, true) # old bundler (deprecated, remove this)
          guard_already_tagged
        elsif respond_to?(:already_tagged?, true) # new bundler
          already_tagged?
        else
          raise "Already tagged! (You may retag by setting RETAG in the env)"
        end
      end

      tag_version do
        git_push if git_push?
        dawanda_push(built_gem_path)
      end
    end

    def rubygem_push(path)
      puts "No, you can't push #{path} to Rubygems (it's DaWanda intellectual properly)"
      exit 1
    end

    def dawanda_push(path)
      remote_path = "/srv/dist.dawanda.in"
      puts "Copying up to #{dawanda}..."
      system "scp -P22998 #{path} #{dawanda_user}@#{dawanda}:#{remote_path}/gems/"
      puts "Copying up to #{dawanda}..."
      system "ssh -p22998 -l #{dawanda_user} #{dawanda} 'cd #{remote_path} && gem generate_index gems'"
      puts "Done! You might want to announce this release on IRC (it doesn't happen automatically, yet)."
    end

    private
    def git_push?
      !!(ENV['NO_PUSH'] || ENV['DONT_PUSH'] || ENV['PUSH'] =~ /^(no|false|0)$/i)
    end

    def retag?
      ENV['RETAG'] =~ /^yes|true|1$/i
    end
  end
end
