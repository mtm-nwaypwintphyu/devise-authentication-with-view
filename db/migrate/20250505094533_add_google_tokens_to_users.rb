class AddGoogleTokensToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_oauth2_token, :text
    add_column :users, :google_oauth2_refresh_token, :string
  end
end
