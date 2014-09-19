require 'open-uri'

class BuildingsSeeder
  # количество генерируемых за один запуск скрипта записей
  COUNT = 50

  # две точки, задающие границы четырехугольника, случайные дома
  # из которого будут добавлены в БД.
  # сейчас точка A - северо-запад Москвы, точка B - юго-восток.
  RECT_A_LAT, RECT_A_LONG = 55.892265, 37.366067
  RECT_B_LAT, RECT_B_LONG = 55.586541, 37.887918

  def seed
    counter = 0
    while counter < COUNT
      point = random_rect_point
      building = closest_building(point)
      if building && !building_exists?(building)
        counter += 1
        building.save!

        print "BuildingSeeder generated #{counter} of #{COUNT} records\r"
        STDOUT.flush
      end
    end
  end

  protected

  def random_rect_point
    @delta_long ||= RECT_B_LONG - RECT_A_LONG
    @delta_lat  ||= RECT_A_LAT  - RECT_B_LAT
    long = RECT_A_LONG + rand * @delta_long
    lat  = RECT_B_LAT  + rand * @delta_lat
    [lat, long]
  end

  def closest_building(point)
    json = inverse_geocode(point)
    building_data = first_result(json)
    building_data ? record_from_json(building_data) : nil
  end

  def inverse_geocode(point)
    lat, long = point
    params = {
      geocode: [lat, long].join(','),
      kind: 'house',
      format: 'json',
      sco: 'latlong'
    }

    url = 'http://geocode-maps.yandex.ru/1.x/?' + params.to_query
    data = open(url, &:read)
    JSON.load(data)
  end

  def first_result(json)
    json['response']['GeoObjectCollection']['featureMember'].first
  end

  def building_exists?(building)
    Building.exists?(address: building.address)
  end

  def record_from_json(result_json)
    geoobject_json = result_json['GeoObject']
    long, lat = geoobject_json['Point']['pos'].split(' ')
    address = geoobject_json['name']
    Building.new(address: address, long: long, lat: lat)
  end
end

BuildingsSeeder.new.seed
