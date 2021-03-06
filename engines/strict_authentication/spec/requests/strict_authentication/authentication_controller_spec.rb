require 'rails_helper'

module StrictAuthentication
  RSpec.describe AuthenticationController, type: :request do
    subject { response }

    let(:system) { FactoryGirl.create(:system, :with_activated_product) }

    describe '#check' do
      context 'without authentication' do
        before { get '/api/auth/check' }
        its(:code) { is_expected.to eq '401' }
      end

      context 'with invalid credentials' do
        before { get '/api/auth/check', headers: basic_auth_header('invalid', 'invalid') }
        its(:code) { is_expected.to eq '401' }
      end

      context 'with valid credentials' do
        include_context 'auth header', :system, :login, :password

        before { get '/api/auth/check', headers: auth_header.merge({ 'X-Original-URI': requested_uri }) }

        context 'when requested path is not activated' do
          let(:requested_uri) { '/repo/some/uri' }

          its(:code) { is_expected.to eq '403' }
        end

        context 'when requesting a file in an activated repo' do
          let(:requested_uri) { '/repo' + system.repositories.first[:local_path] + '/repodata/repomd.xml' }

          its(:code) { is_expected.to eq '200' }
        end

        context 'when requesting a directory in an activated repo' do
          let(:requested_uri) { '/repo' + system.repositories.first[:local_path] + '/' }

          its(:code) { is_expected.to eq '200' }
        end

        context 'when accessing product.license directory' do
          let(:requested_uri) { '/repo/some/uri/product.license/' }

          its(:code) { is_expected.to eq '200' }
        end
      end
    end
  end
end
