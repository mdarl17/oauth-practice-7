class SessionsController < ApplicationController 
	def create
		client_id = "0553da0f47202e004482"
		client_secret = "1c9ba657839e676d92595b23aed80ec3d3dc77f9"
		code = params[:code]
		conn = Faraday.new(url: "https://github.com", headers: {"Accept": "application/json"})

		response = conn.post("/login/oauth/access_token") do |req|
			req.params = {
				"code": code,
				"client_id": client_id,
				"client_secret": client_secret
			}
		end

		data = JSON.parse(response.body, symbolize_names: true)
		access_token = data[:access_token]

		conn = Faraday.new(
			url: "https://api.github.com",
			headers: {
				"Authorization": "token #{access_token}"
			}
		)
		response = conn.get("/user")
		data = JSON.parse(response.body, symbolize_names: true)

		user = User.find_or_create_by(uid: data[:id])

		user.username = data[:login]

		user.uid = data[:id]

		user.token = access_token

		user.save

		session[:user_id] = user.id

		response = Faraday.get("https://api.github.com/user/repos", {
			accept: "application/vnd.github+json", 
			auth: "token #{user.token}"
		})
		
		parsed = JSON.parse(response.body, symbolize_names: true)
		require 'pry'; binding.pry
		redirect_to dashboard_path
	end
end