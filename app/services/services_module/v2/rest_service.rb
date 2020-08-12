class ServicesModule::V2::RestService < ServicesModule::V2::BaseService

  def get(url, headers)
    params = {}
    params[:headers] = headers if !headers.nil?
    params[:debug_output] = STDOUT

    HTTParty.get(url, params)
  end

  def post(url, body, headers = nil)
    params = {}
    params[:body] = body if !body.nil?
    params[:headers] = headers if !headers.nil?
    params[:debug_output] = STDOUT

    HTTParty.post(url, params)
  end

  def put(url, body)
    HTTParty.put(url, { body: body })
  end

  def delete(url)
    HTTParty.delete(url)
  end
end
