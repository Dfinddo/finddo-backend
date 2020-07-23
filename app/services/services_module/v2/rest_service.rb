class ServicesModule::V2::RestService < ServicesModule::V2::BaseService

  def get(url)
    HTTParty.get(url, body: body)
  end

  def post(url, body)
    HTTParty.post(url, body: body)
  end

  def put(url, body)
    HTTParty.put(url, body: body)
  end

  def delete(url)
    HTTParty.delete(url)
  end
end
