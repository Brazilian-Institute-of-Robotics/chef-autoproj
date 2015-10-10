require 'yaml'
require 'set'

def whyrun_supported?
    true
end

action :bootstrap do
    if !needs_bootstrap?(@current_resource, @new_resource)
        Chef::Log.info "#{@new_resource} already bootstrapped - nothing to do"
    else
        if @current_resource.bootstrapped
            Chef::Log.info "#{@new_resource} needs to be rebootstrapped - configuration changed from #{@current_resource.buildconf} to #{@new_resource.buildconf}"
        end

        converge_by("Bootstrapping #{@new_resource}") do
            bootstrap(@new_resource)
        end
    end
end

def needs_bootstrap?(resource, new_resource)
    return true if !@current_resource.bootstrapped

    current = @current_resource.buildconf.map { |k, v| [k.to_sym, v] }.to_set
    new     = @new_resource.buildconf.map { |k, v| [k.to_sym, v] }.to_set
    current != new
end

def bootstrap(resource)
    directory resource.name do
        action :create
        owner resource.user
    end
    bootstrap = ::File.join(resource.dir, 'autoproj_bootstrap')
    remote_file bootstrap do
        source "https://raw.githubusercontent.com/rock-core/autoproj/stable/bin/autoproj_bootstrap"
        action :create
        owner resource.user
    end

    buildconf = resource.buildconf.dup
    vcs_type = buildconf.delete('type')
    vcs_url  = buildconf.delete('url')
    vcs_options = buildconf.map { |k, v| "'#{k}=#{v}'" }

    exec_resource =
        if resource.rbenv then :script
        else :rbenv_script
        end

    send(exec_resource, "autoproj bootstrap") do
        environment 'AUTOPROJ_BOOTSTRAP_IGNORE_NONEMPTY_DIR' => '1', 'AUTOPROJ_OSDEPS_MODE' => 'all'
        code "#{resource.ruby} '#{bootstrap}' '#{vcs_type}' '#{vcs_url}' #{vcs_options.join(" ")}"
        cwd resource.dir
        user resource.user
    end
end

action :build do
    converge_by("Building #{@new_resource}") do
        resource = @new_resource
        if needs_bootstrap?(resource)
            directory resource.dir do
                action :delete
            end
            bootstrap(resource)
        end

        gem_home = ::File.join(resource.dir, '.gems')
        rbenv_script "autoproj update" do
            environment "GEM_HOME" => gem_home
            cwd resource.dir
            code "#{::File.join(gem_home, 'bin', 'autoproj')} update"
            user resource.user
        end
        rbenv_script "autoproj build" do
            environment "GEM_HOME" => gem_home
            cwd resource.dir
            code "#{::File.join(gem_home, 'bin', 'autoproj')} build"
            user resource.user
        end
    end
end

def load_current_resource
    @current_resource = Chef::Resource::AutoprojWorkspace.new(@new_resource.name)
    @current_resource.dir(@new_resource.name)
    @current_resource.buildconf(Hash.new)
    @current_resource.bootstrapped = false

    if ::File.directory?(dir = ::File.join(@current_resource.dir, 'autoproj'))
        @current_resource.bootstrapped = true
        if ::File.file?(config_file = ::File.join(dir, 'config.yml'))
            config = YAML.load(::File.read(config_file))
            @current_resource.buildconf(config['manifest_source'])
        end
    end
end

