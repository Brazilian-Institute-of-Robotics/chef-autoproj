
def whyrun_supported?
    true
end

action :update do
    current_config, base_config = load_current_config(@new_resource.dir)
    new_config = Chef::Mixin::DeepMerge.deep_merge!(base_config, @new_resource.variables)
    if current_config == new_config
        Chef::Log.info "#{@new_resource} up-to-date"
    else
        converge_by("Updating #{@new_resource}") do
            config_path = ::File.join(@new_resource.dir, 'autoproj', 'config.yml')
            ::File.open(config_path, 'w') do |io|
                io.write YAML.dump(new_config)
            end
        end
    end
end

def load_current_config(dir)
    current_config_path = ::File.join(dir, 'autoproj', 'config.yml')
    current_config = YAML.load(::File.read(current_config_path))

    base_config_path = ::File.join(dir, 'autoproj', 'config.yml.chef-orig')
    if !::File.exist?(base_config_path)
        base_config = current_config
        ::FileUtils.cp current_config_path, base_config_path
    else
        base_config = YAML.load(::File.read(base_config_path))
    end

    return current_config, base_config
end

def load_current_resource
    @current_resource = Chef::Resource::AutoprojConfig.new(@new_resource.name)
    @current_resource.dir(@new_resource.name)
end
        

