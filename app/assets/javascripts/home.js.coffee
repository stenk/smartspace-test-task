CIRCLE_RADIUS = 4000

window.initMap = (buildings) -> ymaps.ready ->
  map = new ymaps.Map('map', center: [55.76, 37.64], zoom: 10)

  for building in buildings
    placemark = createPlacemark(building)
    map.geoObjects.add placemark

  circle = new ymaps.Circle([null, CIRCLE_RADIUS])
  map.geoObjects.add circle

  handler = clickHandler(map, circle)
  map.events.add 'click', handler
  circle.events.add 'click', handler

  displayTable []

clickHandler = (map, circle) -> (event) ->
  if map.balloon.isOpen()
    map.balloon.close()
  else
    clickCoords = event.get('coords')
    circle.geometry.setCoordinates clickCoords

    query = ymaps
      .geoQuery map.geoObjects
      .search 'geometry.type = "Point"'
      .setOptions 'preset', 'islands#blueIcon'
      .searchInside circle
      .setOptions 'preset', 'islands#redIcon'

    innerPoints = iterableToArray(query)
    geo = ymaps.coordSystem.geo
    for placemark in innerPoints
      placemarkCoords = placemark.geometry.getCoordinates()
      placemark.distance = geo.getDistance(clickCoords, placemarkCoords)
    innerPoints.sort (a, b) -> a.distance - b.distance

    displayTable innerPoints

createPlacemark = (building) ->
  placemark = new ymaps.Placemark(
    [building.lat, building.long],
    balloonContentHeader: building.address,
    balloonContent: "Широта: #{building.lat}<br>Долгота: #{building.long}",
    balloonContentFooter: "id: #{building.id}"
  )
  placemark.building = building
  placemark

iterableToArray = (ymapsIterable) ->
  array = []
  iterator = ymapsIterable.getIterator()
  while (item = iterator.getNext()) != iterator.STOP_ITERATION
    array.push item
  array

displayTable = (placemarks) ->
  $('.search-results').remove()

  html  = '<table class="search-results">'
  html += '<tr><th>Адрес</th><th>Расстояние</th></tr>'
  for placemark in placemarks
    html += '<tr>'
    html += "<td>#{placemark.building.address}</td>"
    html += "<td>#{ymaps.formatter.distance(placemark.distance)}</td>"
    html += '</tr>'
  html += '</table>'

  $(html).appendTo(document.body)
