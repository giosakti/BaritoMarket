class AppGroup < ApplicationRecord
  validates :name, presence: true

  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :barito_apps
  has_many :app_group_users
  has_many :users, through: :app_group_users
  has_one :infrastructure

  def self.setup(env, params)
    ActiveRecord::Base.transaction do
      app_group = AppGroup.create(name: params[:name], created_by_id: params[:user_id])
      infrastructure = Infrastructure.setup(
        env,
        name: params[:name],
        capacity: params[:capacity],
        app_group_id: app_group.id,
      )

      [app_group, infrastructure]
    end
  end
end
