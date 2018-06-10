class BaritoAppBuilder
  attr_accessor :barito_app, :blueprint, :env

  def initialize(name, tps_config, app_group, env)
    @barito_app = BaritoApp.new(
      name:         name,
      tps_config:   tps_config,
      app_group:    app_group,
      secret_key:   BaritoApp.generate_key,
      cluster_name: Rufus::Mnemo.from_i(BaritoApp.generate_cluster_index),
      app_status:   BaritoApp.app_statuses[:inactive],
      setup_status: BaritoApp.setup_statuses[:pending],
    )
    @blueprint = nil
    @env = env
  end

  def persisted?
    @barito_app.persisted?
  end

  def errors
    @barito_app.errors
  end

  def save 
    @barito_app.save if @barito_app.valid?
    @barito_app
  end

  def generate_blueprint
    @blueprint = Blueprint.new(@barito_app, env) unless @blueprint.present?
  end

  def process_blueprint
    if @blueprint.present?
      path = @blueprint.generate_file
      BlueprintWorker.perform_async(path)
    end
  end

  def self.setup(args)
    builder = self.new(args[:name], args[:tps_config], args[:app_group], args[:env])
    builder.save
    unless builder.errors.present?
      builder.generate_blueprint
      builder.process_blueprint
    end
    builder
  end
end
