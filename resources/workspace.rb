actions :bootstrap, :update, :build
default_action :build

# The definition of the build configuration for the bootstrap
#
# 'type' and 'url' are the first two argument to boostrap and the rest are
# passed as key=value
attribute :buildconf, kind_of: Hash,
    required: true

# The ruby interpreter
attribute :ruby, kind_of: String,
    default: 'ruby'
attribute :user, kind_of: String,
    required: true
attribute :dir, name_attribute: true, kind_of: String,
    required: true
attribute :cache_dir, kind_of: String,
    required: false
attribute :update, default: false
attribute :seed_config, kind_of: String

attr_accessor :bootstrapped
