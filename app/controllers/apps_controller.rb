class AppsController < ApplicationController
  def index
    @apps = BaritoApp.all
  end

  def new
    @app = BaritoApp.new
    @app_groups = Figaro.env.app_groups.split(',')
    @tps_options = TPS_CONFIG.keys.map(&:capitalize)
  end

  def create
    builder = BaritoAppBuilder.setup(barito_app_params.merge(env: Rails.env))
    @app = builder.barito_app
    if @app.valid?
      return redirect_to root_path
    else
      flash[:messages] = @app.errors.full_messages
      return redirect_to new_app_path
    end
  end

  def show
    @app = BaritoApp.find(params[:id])
  end

  private

  def barito_app_params
    params.
      require(:barito_app).
      permit(:name, :tps_config, :app_group).
      tap do |x|
        x[:tps_config]  = x[:tps_config].downcase
        x[:app_group]   = x[:app_group].downcase
      end
  end
end
