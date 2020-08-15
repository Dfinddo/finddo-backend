class ServicesModule::V2::RestService < ServicesModule::V2::BaseService

  def get(url, headers = nil)
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

  def put(url, body, headers = nil)
    params = {}
    params[:body] = body if !body.nil?
    params[:headers] = headers if !headers.nil?
    params[:debug_output] = STDOUT

    HTTParty.put(url, params)
  end

  def delete(url, headers = nil)
    params = {}
    params[:headers] = headers if !headers.nil?
    params[:debug_output] = STDOUT

    HTTParty.delete(url, params)
  end
end
