class BaritoApp < ActiveRecord::Base
  CLUSTER_NAME_PADDING = 1000
  validates :name, :tps_config, :app_group, :secret_key, :cluster_name, :setup_status, :app_status,
    presence: true
  validates :app_group, inclusion: { in: Figaro.env.app_groups.split(',').map(&:downcase) }
  validate  :tps_config_valid_key?

  enum app_statuses: {
    inactive: 'INACTIVE',
    active: 'ACTIVE',
  }
  enum setup_statuses: {
    pending: 'PENDING',
    provisioning_started: 'PROVISIONING_STARTED',
    provisioning_error: 'PROVISIONING_ERROR',
    provisioning_finished: 'PROVISIONING_FINISHED',
    bootstrap_started: 'BOOTSTRAP_STARTED',
    bootstrap_error: 'BOOTSTRAP_ERROR',
    finished: 'FINISHED',
  }

  def self.setup(name, tps_config, app_group, env)
    barito_app = BaritoApp.new(
      name:         name,
      tps_config:   tps_config,
      app_group:    app_group,
      secret_key:   BaritoApp.generate_key,
      cluster_name: Rufus::Mnemo.from_i(BaritoApp.generate_cluster_index),
      app_status:   BaritoApp.app_statuses[:inactive],
      setup_status: BaritoApp.setup_statuses[:pending],
    )
    if barito_app.valid?
      barito_app.save
      blueprint = Blueprint.new(barito_app, env)
      blueprint_path = blueprint.generate_file
      BlueprintWorker.perform_async(blueprint_path)
    end
    barito_app
  end

  def update_app_status(status)
    status = status.downcase.to_sym
    if BaritoApp.app_statuses.key?(status)
      update_attribute(:app_status, BaritoApp.app_statuses[status])
    else
      false
    end
  end

  def update_setup_status(status)
    status = status.downcase.to_sym
    if BaritoApp.setup_statuses.key?(status)
      update_attribute(:setup_status, BaritoApp.setup_statuses[status])
    else
      false
    end
  end

  def tps_config_valid_key?
    config_types = TPS_CONFIG.keys.map(&:downcase)
    errors.add(:tps_config, 'Invalid Config Value') unless config_types.include?(tps_config)
  end

  def increase_log_count(new_count)
    update_column(:log_count, log_count + new_count.to_i)
  end

  def self.generate_cluster_index
    BaritoApp.all.size + CLUSTER_NAME_PADDING
  end

  def self.secret_key_valid?(token)
    BaritoApp.find_by_secret_key(token).present?
  end

  def self.generate_key
    SecureRandom.uuid.gsub(/\-/, '')
  end
end
