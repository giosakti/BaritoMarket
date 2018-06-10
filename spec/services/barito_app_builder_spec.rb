require 'rails_helper'

RSpec.describe BaritoAppBuilder do
  describe 'Setup Application' do
    let(:barito_app_props) { build(:barito_app) }

    before do
      allow(SecureRandom).to receive(:uuid).
        and_return(barito_app_props.secret_key)
      allow(BaritoApp).to receive(:generate_cluster_index).
        and_return(1000)
      allow(Rufus::Mnemo).to receive(:from_i).with(1000).
        and_return(barito_app_props.cluster_name)
      Sidekiq::Testing.fake!
    end

    context 'valid properties' do
      before(:each) do
        builder = BaritoAppBuilder.setup(
          name:       barito_app_props.name,
          tps_config: barito_app_props.tps_config,
          app_group:  barito_app_props.app_group,
          env:        Rails.env,
        )
        @barito_app = builder.barito_app
      end

      it 'should create and save barito_app' do
        expect(@barito_app.persisted?).to eq(true)
        expect(@barito_app.setup_status).to eq(BaritoApp.setup_statuses[:pending])
        expect(@barito_app.app_status).to eq(BaritoApp.app_statuses[:inactive])
      end

      it 'should generate cluster name' do
        expect(@barito_app.cluster_name).to eq(
          Rufus::Mnemo.from_i(BaritoApp.generate_cluster_index),
        )
      end

      it 'should generate secret key' do
        expect(@barito_app.secret_key).to eq(barito_app_props.secret_key)
      end

      it 'should increase log_count' do
        @barito_app.increase_log_count(1)
        expect(@barito_app.log_count).to eq 1
      end

      it 'should generate blueprint file' do
        blueprint = Blueprint.new(@barito_app, Rails.env)
        file_path = "#{Rails.root}/blueprints/jobs/#{blueprint.filename}.json"
        expect(File.exist?(file_path)).to eq(true)
      end
    end

    context 'invalid properties' do
      it 'shouldn\'t create application if app_group is invalid' do
        builder = BaritoAppBuilder.setup(
          name:       barito_app_props.name,
          tps_config: barito_app_props.tps_config,
          app_group:  'invalid_group',
          env:        Rails.env,
        )
        barito_app = builder.barito_app
        expect(barito_app.persisted?).to eq(false)
        expect(barito_app.valid?).to eq(false)
      end

      it 'shouldn\'t create application if tps_config is invalid' do
        builder = BaritoAppBuilder.setup(
          name:       barito_app_props.name,
          tps_config: 'invalid_config',
          app_group:  barito_app_props.app_group,
          env:        Rails.env,
        )
        barito_app = builder.barito_app
        expect(barito_app.persisted?).to eq(false)
        expect(barito_app.valid?).to eq(false)
      end
    end
  end
end
