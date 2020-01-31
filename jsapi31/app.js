function addDraggableMarker(map, behavior) {

    var marker = new H.map.Marker({
        lat: latitud,
        lng: longitud
    }, {
        volatility: true
    });

    // Ensure that the marker can receive drag events
    marker.draggable = true;
    map.addObject(marker);

    // disable the default draggability of the underlying map
    // and calculate the offset between mouse and target's position
    // when starting to drag a marker object:

    map.addEventListener('dragstart', function(ev) {
        var target = ev.target,
            pointer = ev.currentPointer;

        if (target instanceof H.map.Marker) {
            var targetPosition = map.geoToScreen(target.getGeometry());
            target['offset'] = new H.math.Point(pointer.viewportX - targetPosition.x, pointer.viewportY - targetPosition.y);
            behavior.disable();

        }
    }, false);


    // re-enable the default draggability of the underlying map
    // when dragging has completed
    map.addEventListener('dragend', function(ev) {
        var target = ev.target;
        if (target instanceof H.map.Marker) {

            $('#long').val(ev.target.b.lng);
            $('#lat').val(ev.target.b.lat);

            behavior.enable();
        }
    }, false);

    // Listen to the drag event and move the position of the marker
    // as necessary
    map.addEventListener('drag', function(ev) {
        var target = ev.target,
            pointer = ev.currentPointer;
        if (target instanceof H.map.Marker) {
            target.setGeometry(map.screenToGeo(pointer.viewportX - target['offset'].x, pointer.viewportY - target['offset'].y));
        }
    }, false);
}


//url parameters
var query_string = {};
var query = window.location.search.substring(1);
var vars = query.split("&");


for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    if (typeof query_string[pair[0]] === "undefined") {
        query_string[pair[0]] = decodeURIComponent(pair[1]);
    } else if (typeof query_string[pair[0]] === "string") {
        var arr = [query_string[pair[0]], decodeURIComponent(pair[1])];
        query_string[pair[0]] = arr;
    } else {
        query_string[pair[0]].push(decodeURIComponent(pair[1]));
    }
}

var latitud = query_string.lat;
var longitud = query_string.long;
var apiKey = query_string.apiKey;

/**
 * Boilerplate map initialization code starts below:
 */

//Step 1: initialize communication with the platform
// In your own code, replace variable window.apikey with your own apikey
var platform = new H.service.Platform({
    apikey: apiKey
});

var defaultLayers = platform.createDefaultLayers();
//Step 2: initialize a map - this map is centered over Boston
var map = new H.Map(document.getElementById('map'),
    defaultLayers.raster.normal.map, {
        center: {
            lat: latitud,
            lng: longitud
        },
        engineType: H.map.render.RenderEngine.EngineType.P2D,
        zoom: 12,
        pixelRatio: window.devicePixelRatio || 1
    });

// add a resize listener to make sure that the map occupies the whole container
//window.addEventListener('resize', () => map.getViewPort().resize());
window.addEventListener('resize', function() {
    map.getViewPort().resize();
});
window.setTimeout(function() {
    alert("time");
    map.getViewPort().resize();
}, 1000);

//Step 3: make the map interactive
// MapEvents enables the event system
// Behavior implements default interactions for pan/zoom (also on mobile touch environments)
//var behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));
var behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));

// Step 4: Create the default UI:
var ui = H.ui.UI.createDefault(map, defaultLayers, 'en-US');

// Add the click event listener.
addDraggableMarker(map, behavior);