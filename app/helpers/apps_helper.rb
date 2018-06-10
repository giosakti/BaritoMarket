module AppsHelper
  def status(app)
    if app.app_status.eql?(BaritoApp.app_statuses[:inactive])
      app.setup_status
    else
      app.app_status
    end
  end

  def inactive?(app)
    app.app_status.eql?(BaritoApp.app_statuses[:inactive])
  end

  def tps_size(app)
    TPS_CONFIG[app.tps_config]['tps_limit']
  end

  def tps_name(app)
    TPS_CONFIG[app.tps_config]['name']
  end
end
