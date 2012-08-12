class DevicesController < ApplicationController
  doorkeeper_for :index, :show, scopes: [:read, :write]
  doorkeeper_for :create, :update, :destroy, scopes: [:write]

  before_filter :find_owned_resources
  before_filter :find_resource,     only: %w(show update destroy)
  before_filter :search_params,     only: %w(index)
  before_filter :search_properties, only: %w(index)
  before_filter :pagination,        only: %w(index)

  def index
    @devices = @devices.limit(params[:per])
  end

  def show
  end

  def create
    @device = Device.new(params)
    @device.resource_owner_id = current_user.id
    if @device.save!
      render 'show', status: 201, location: DeviceDecorator.decorate(@device).uri
    else
      render_422 'notifications.resource.not_valid', @device.errors
    end
  end

  def update
    if @device.update_attributes!(params)
      render 'show'
    else
      render_422 'notifications.resource.not_valid', @device.errors
    end
  end

  def destroy
    render 'show'
    @device.destroy
  end

  private

  def find_owned_resources
    @devices = Device.where(resource_owner_id: current_user.id)
  end

  def find_resource
    @device = @devices.find(params[:id])
  end

  def search_params
    @devices = @devices.where('name'    => /.*#{params[:name]}.*/i) if params[:name]
    @devices = @devices.where('type_id' => find_id(params[:type]))  if params[:type]
  end

  def search_properties(match = {})
    match.merge!({ property_id: Moped::BSON::ObjectId(find_id(params[:property])) }) if params[:property]
    match.merge!({ value: params[:value] }) if params[:value]
    match.merge!({ physical: params[:physical] }) if params[:physical]
    @devices = @devices.where('properties' => { '$elemMatch' => match })
  end

  def pagination
    params[:per] = (params[:per] || Settings.pagination.per).to_i
    params[:per] = Settings.pagination.per if params[:per] == 0 
    params[:per] = Settings.pagination.max_per if params[:per] > Settings.pagination.max_per
    @devices = @devices.gt(id: find_id(params[:start])) if params[:start]
  end
end
