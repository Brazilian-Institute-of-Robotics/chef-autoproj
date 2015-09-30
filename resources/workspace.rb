actions :bootstrap, :update, :build
default_action :build

attribute :buildconf, kind_of: Hash,
    required: true

# The ruby interpreter
attribute :ruby, kind_of: String,
    default: 'ruby'
attribute :user, kind_of: String,
    required: true
attribute :dir, name_attribute: true, kind_of: String,
    required: true
attribute :update, default: false
attribute :seed_config, kind_of: String

attr_accessor :bootstrapped
