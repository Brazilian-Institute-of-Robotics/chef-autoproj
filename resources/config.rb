actions :update
default_action :update

attribute :dir, name_attribute: true, kind_of: String,
    required: true
attribute :user, kind_of: String,
    required: true
attribute :variables, kind_of: Hash,
    required: true

