class DeviceProperty
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uri
  field :name
  field :value

  attr_accessible :uri, :name, :value

  validates :uri, url: true
  validates :name, presence: true

  embedded_in :device
end