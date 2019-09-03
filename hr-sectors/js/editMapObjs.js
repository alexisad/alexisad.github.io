//(function() {
var initEditTool = function() {
    window.H = window.H || {};
    window.map = window.map || {};
    window.Kefir = window.Kefir || {};
    window.behavior = window.behavior || {};

    var nodeSVG = [
        '<svg height="16" width="16" xmlns="http://www.w3.org/2000/svg">',
        '<circle cx="8" cy="4" r="8" stroke="black" stroke-width="1" fill="{%fill}" />',
        '</svg>'
    ].join("");

    window.editTool = window.editTool || {};
    var editTool = window.editTool,
        streamCtxMapMenu = editTool.streamCtxMapMenu = Kefir.fromEvents(map, 'contextmenu'),
        streamEnterMap = Kefir.fromEvents(map, 'pointerenter'),
        streamLeaveMap = Kefir.fromEvents(map, 'pointerleave'),
        streamPtrMove = Kefir.fromEvents(map, 'pointermove');

    editTool.plSet = new H.map.Group();
    map.addObject(editTool.plSet);

    editTool.sampleStitchPLine = new H.map.Polyline(new H.geo.Strip([1, 1, 0, 2, 2, 0]), { zIndex: 99 });
    editTool.sampleStitchPLine.setVisibility(false);
    editTool.sampleStitchPLine.setArrows({
        fillColor: "green",
        width: 4,
        length: 5
    });
    editTool.sampleStitchPLine.setStyle({
        lineWidth: 4
    });
    editTool.selectedPls = [];
    map.addObject(editTool.sampleStitchPLine);


    //-------------------------------------------------------------------------------------
    var ctrlCtxMenu = function(v) {
        if (!v) return;
        //console.log("streamCtxMenu_EnterMap:: ", v);
        editTool.rClickCoords = map.screenToGeo(v.viewportX, v.viewportY);
        //console.log("streamCtxMenu_EnterMap:: ", this, this.rClickCoords);
        editTool.curPolyline = editTool.curPolyline || {};
        editTool.curPolyline.status = "wait";

        if (!editTool.curPolyline.polyline) {
            try {
                map.removeObject(editTool.polylineNameMarker); //remove previosely not completed fence
            } catch (e) {};
            var newLine = new H.util.ContextItem({
                label: 'new polyline',
                callback: function() {


                    var domElement = $("<div>"),
                        lblPlName = $("<label>"),
                        inpName = $("<input class='inp-name' placeholder='set name of the fence...'>"),
                        inpOk = $("<input class='btn-ok'>"),
                        inpCancel = $("<input class='btn-cancel'>"),
                        contB = $("<div>");

                    domElement.css("backgroundColor", '#737e84');
                    domElement.css("color", '#fff');
                    domElement.css("padding", '5px');

                    inpOk.attr("type", "button");
                    inpCancel.attr("type", "button");
                    inpOk.attr("value", "ok");
                    inpOk.css("float", "right");


                    inpCancel.attr("value", "cancel");
                    inpCancel.css("display", "block");
                    inpOk.css("display", "block");
                    inpCancel.css("float", "right");

                    contB.append(inpOk, inpCancel);

                    lblPlName.text("fence name: ");
                    domElement.append(lblPlName);
                    domElement.append(inpName);
                    domElement.append(contB);

                    var polylineName = editTool.polylineNameMarker = new H.map.DomMarker(this.rClickCoords, {
                        icon: new H.map.DomIcon(domElement[0], {
                            onAttach: function(el, domIcon, domMarker) {
                                //console.log("el:: ", $(el).find(".btn-ok"));
                                var inpOk = $(el).find(".btn-ok"),
                                    inpCancel = $(el).find(".btn-cancel"),
                                    inpName = $(el).find(".inp-name"),

                                    stmClickOk = Kefir.fromEvents(inpOk[0], "click"),
                                    stmKeyName = Kefir.fromEvents(inpName[0], "keypress"),
                                    stmCancel = Kefir.fromEvents(inpCancel[0], "click"),

                                    stmSaveName = Kefir.combine([Kefir.constant(false).concat(stmClickOk), Kefir.constant(false).concat(stmKeyName)], function(stmOk, stmEnter) {
                                        if (stmEnter && stmEnter.keyCode == 13) {
                                            return true;
                                        }
                                        if (stmOk) {
                                            return true;
                                        }
                                        return false;
                                    });

                                inpName.focus();

                                var rstmSaveName = stmSaveName
                                    .map(function(v) {
                                        //console.log("rstmSaveName:: ", v, inpName.val());
                                        if (v && inpName.val() != "") {
                                            return inpName.val();
                                        } else {
                                            return false;
                                        }
                                    })
                                    .filter(function(v) {
                                        return v;
                                    });

                                rstmSaveName
                                    .onValue(function(v) {
                                        //console.log("stmSaveName v:: ", v);
                                        map.removeObject(editTool.polylineNameMarker);

                                        this.curPolyline = {
                                            status: "start",
                                            name: v,
                                            coords: [
                                                this.rClickCoords
                                            ],
                                            strip: new H.geo.Strip([
                                                this.rClickCoords.lat,
                                                this.rClickCoords.lng,
                                                0
                                            ]),
                                            polyline: false
                                        };
                                    }.bind(editTool));

                                stmCancel
                                    .onValue(function(v) {
                                        map.removeObject(editTool.polylineNameMarker);
                                    });
                            }
                        })
                    });
                    map.addObject(polylineName);

                    //console.log("editTool.curPolyline:: ", editTool.curPolyline);
                }.bind(editTool)
            });
        } else {
            var newNode = new H.util.ContextItem({
                label: 'new node',
                callback: function() {
                    //console.log(this.rClickCoords);
                    this.curPolyline.status = "add new node";
                }.bind(editTool)
            });
            var stopLine = new H.util.ContextItem({
                label: 'stop polyline',
                callback: function() {
                    var coord = this.rClickCoords,
                        pLine = this.curPolyline.polyline,
                        currNode = createNode(coord, pLine, "last"),
                        nodeData = currNode.getData();

                    changeStripByChangeNode(coord, nodeData.pIdxNode, pLine);

                    //console.log(this.rClickCoords);
                    this.curPolyline.status = "stop";
                    this.curPolyline = false;

                }.bind(editTool)
            });
        }

        if (newLine)
            v.items.push(newLine);
        if (newNode)
            v.items.push(newNode);
        if (stopLine)
            v.items.push(stopLine);
    };


    editTool.poolEvents = Kefir.pool();
    editTool.poolEvents.plug(Kefir.constant(false));
    editTool.poolEvents.plug(streamLeaveMap);

    editTool.streamCtxMenu_EnterMap = Kefir.combine(
        [Kefir.constant(true).concat(streamEnterMap), Kefir.constant(true).concat(streamLeaveMap), streamCtxMapMenu], [editTool.poolEvents],
        function(a, b, c, d) {
            if (a == true || b == true) {
                return c;
            }
            if (d.target && d.target.getId && editTool.curPolyline.polyline && d.target.getId() == editTool.curPolyline.polyline.getId()) {
                return c;
            }
            //console.log("a,b,c :: ", d);
            if (a.originalEvent.timeStamp < b.originalEvent.timeStamp || a.originalEvent.timeStamp > c.originalEvent.timeStamp) {
                return false;
            } else {
                return c;
            }

        });


    var rstreamCtxMenu_EnterMap = editTool.streamCtxMenu_EnterMap
        .filter(function(v) {
            return v;
        });

    rstreamCtxMenu_EnterMap
        .onValue(ctrlCtxMenu);


    var rstreamPtrMove = streamPtrMove
        .filter(function(v) {
            //console.log("rstreamPtrMove this.curPolyline:: ", this.curPolyline);
            return (this.curPolyline && (this.curPolyline.status == "start" || this.curPolyline.status == "add new node"));
        }.bind(editTool));
    rstreamPtrMove
        .onValue(function(v) {

            var coord = map.screenToGeo(v.currentPointer.viewportX, v.currentPointer.viewportY),
                s = this.curPolyline.strip,
                cntNodes = s.getPointCount(),
                pLine = this.curPolyline.polyline,
                currNode,
                pIdxNode,
                nodeMarkers;

            if (cntNodes > 1 && this.curPolyline.status != "add new node") { //is not first node polyline
                s.removePoint(cntNodes - 1);
            } else {
                //console.log("first node polyline:: ");
                pIdxNode = cntNodes - 1;
                if (pLine) {
                    currNode = createNode(s.extractPoint(pIdxNode), pLine, pIdxNode);
                }

                //console.log("1. createNode", pLine);
            }

            //console.log("map.geoToScreen(coord):: ", );
            s.pushPoint(map.screenToGeo(map.geoToScreen(coord).x - 5, map.geoToScreen(coord).y - 5));

            if (!pLine) {
                var pLineGrp = new H.map.Group();
                //console.log("this.curPolyline:: ", this.curPolyline);
                pLine = this.curPolyline.polyline = new H.map.Polyline(s, {
                    zIndex: 99,
                    style: {
                        lineWidth: 4
                            //lineDash: [5,5]
                    }
                });
                pLineGrp.addObject(pLine);
                pLineGrp.setData({
                    polyline: pLine
                });

                editTool.plSet.addObject(pLineGrp);

                ctrlPolylineEvents(pLine);

                nodeMarkers = new H.map.Group();
                pLine.setData({
                    nodeMarkers: nodeMarkers,
                    name: this.curPolyline.name
                });
                pLineGrp.addObject(nodeMarkers);

                currNode = createNode(s.extractPoint(pIdxNode), pLine, pIdxNode);


                if (pIdxNode == 0 && currNode) { //first node
                    nodeMarkers.addObject(currNode);
                }


                this.curPolyline.strip = pLine.getGeometry();
                pIdxNode = 0;

                currNode.setData({
                    polyline: pLine,
                    pIdxNode: pIdxNode
                });

            } else {
                pLine.setGeometry(s); //setStrip(s);

                this.curPolyline.status = "start";
            }

        }.bind(editTool));



    //--------------------------------------------------------------------------------

    var ctrlPolylineEvents = function(pLine) {


        var plData = pLine.getData();
        if (!plData) {
            plData = {};
            pLine.setData(plData);
            plData = pLine.getData();
        }
        //console.log("ctrlPolylineEvents:: ", pLine);

        plData.stmPlineCtxMenu = Kefir.fromEvents(pLine, "contextmenu");
        var stmPlineEnter = Kefir.fromEvents(pLine, "pointerenter");
        var stmPlineLeave = Kefir.fromEvents(pLine, "pointerleave");
        var stmPlineTap = Kefir.fromEvents(pLine, "tap");

        editTool.poolEvents.plug(plData.stmPlineCtxMenu);

        var rstmPlineCtxMenu = plData.stmPlineCtxMenu
            .filter(function(v) {
                if (!this.curPolyline) {
                    return true;
                }
                return (this.curPolyline && this.curPolyline.status != "start");
            }.bind(editTool));

        rstmPlineCtxMenu
            .onValue(function(v) {

                var deletePl = new H.util.ContextItem({
                    label: 'delete polyline',
                    callback: function() {
                        var pLine = this.target,
                            grppLine = pLine.getParentGroup();

                        editTool.plSet.removeObject(grppLine);
                        //console.log("delete polyline:: ", this , this.target.getRootGroup());
                    }.bind(v)
                });
                var toPolygon = new H.util.ContextItem({
                    label: 'convert to polygon',
                    callback: function() {
                        var pLine = this.target,
                            grppLine = pLine.getParentGroup(),
                            nPolyg;
                        try {
                            var d = pLine.getData();
                            grppLine.removeObject(d.polygon);
                        } catch (e) {
                            console.error("error polygon:", e);
                        }
                        var geoLine = pLine.getGeometry();
                        //geoLine.pushPoint(geoLine.extractPoint(0));
                        //console.log("extractPoint: ", geoLine.extractPoint(0));
                        grppLine.addObject(nPolyg = new H.map.Polygon(
                            geoLine, {
                                zIndex: 9,
                                style: {
                                    lineWidth: 4
                                }
                            }));
                        var d = pLine.getData();
                        d.polygon = nPolyg;
                        pLine.setData(d);
                        console.log("pLine data: ", pLine.getData(), pLine.getGeometry(), nPolyg.getGeometry().getExterior());
                        var arrPoint = [];
                        pLine.getGeometry().eachLatLngAlt(function(lat, lng, alt, idx) {
                            arrPoint.push(map.geoToScreen(new H.geo.Point(lat, lng)));
                        });
                        window.editTool.onUpdate();
                    }.bind(v)
                });

                if (deletePl) v.items.push(deletePl);
                if (toPolygon) v.items.push(toPolygon);
            });

        stmPlineEnter
            .onValue(function(v) {
                //console.log("stmPlineEnter", v);

                var coord = map.screenToGeo(v.currentPointer.viewportX, v.currentPointer.viewportY),
                    pLine = v.target,
                    dataPLine = pLine.getData(),
                    tmp = //console.log("dataPLine:: ", dataPLine),
                    domElement = $("<div>"),
                    tmp = domElement.text(dataPLine.name),
                    pLineInfo;

                domElement.css("margin", "10px");
                domElement.css("padding", "10px");
                domElement.css("border", "1px #fff solid");
                domElement.css("backgroundColor", '#737e84');
                domElement.css("color", '#fff');

                pLineInfo = editTool.pLineInfo = new H.map.DomMarker(coord, {
                    icon: new H.map.DomIcon(domElement[0])
                });

                map.addObject(pLineInfo);

            });

        stmPlineLeave
            .onValue(function(v) {
                //console.log("editTool.pLineInfo:: ", editTool.pLineInfo);
                try {
                    map.removeObject(editTool.pLineInfo);
                } catch (e) {};

            });

        stmPlineTap
            .onValue(function(v) {
                //console.log("stmPlineTap:: ", v.target, editTool.selectedPls);
                var pLine = v.target,
                    plData = pLine.getData(),
                    selectedPls = editTool.selectedPls;

                if (plData.selected) {
                    plData.selected = false;
                    changeNodeColor(pLine, "#fff");

                    /*var i=0;
                    for(;i<selectedPls.length;i++ ){
                    	if(selectedPls[i].getId() == pLine.getId()){
                    		break;
                    	}
                    }
                    selectedPls.splice(i);*/

                } else /* if(selectedPls.length < 2)*/ {
                    plData.selected = true;
                    changeNodeColor(pLine, "yellow");

                    //selectedPls.push(pLine);
                }

                pLine.setData(plData);


            });

        pLine.setData(plData);

    };

    //----------------------------------------------------------------------------------------------------

    editTool.ctrlCtxNodeMenu = function(v) {

        var nodeData = this.getData(),
            pLine = nodeData.polyline,
            strip = pLine.getGeometry(),
            countNodes = strip.getPointCount();
        //console.log("streamCtxNodeMenu::", this.getData(), nodeData.polyline, strip.getPointCount());

        var deleteNode = new H.util.ContextItem({
            label: 'delete node',
            callback: function() {
                var nodeData = this.getData(),
                    pLine = nodeData.polyline,
                    strip = pLine.getGeometry(),
                    pLineData = pLine.getData(),
                    pIdxNode = nodeData.pIdxNode;

                strip.removePoint(pIdxNode);
                pLine.setGeometry(strip);
                pLineData.nodeMarkers.removeAll();

                strip.eachLatLngAlt(function(lat, lng, alt, idx) {
                    createNode(new H.geo.Point(lat, lng), pLine, idx);
                });

            }.bind(this)
        });

        var addNode = new H.util.ContextItem({
            label: 'add node',
            callback: function() {
                var nodeData = this.getData(),
                    pLine = nodeData.polyline,
                    strip = pLine.getGeometry(),
                    pLineData = pLine.getData(),
                    pIdxNode = nodeData.pIdxNode,
                    coord = strip.extractPoint(pIdxNode);

                strip.insertPoint(pIdxNode, map.screenToGeo(map.geoToScreen(coord).x - 15, map.geoToScreen(coord).y + 15));
                pLine.setGeometry(strip);
                pLineData.nodeMarkers.removeAll();

                strip.eachLatLngAlt(function(lat, lng, alt, idx) {
                    createNode(new H.geo.Point(lat, lng), pLine, idx);
                });


                //map.removeObject(this);
                //console.log("args:: ", arguments, this.getData());
            }.bind(this)
        });

        var revertNode = new H.util.ContextItem({
            label: 'revert node',
            callback: function() {
                var nodeData = this.getData();

                this.setPosition(nodeData.oldCoord);
                changeStripByChangeNode(nodeData.oldCoord, nodeData.pIdxNode, nodeData.polyline);

            }.bind(this)
        });


        if (addNode) v.items.push(addNode);
        if (revertNode && nodeData.oldCoord) v.items.push(revertNode);
        if (deleteNode) v.items.push(deleteNode);
    };

    //-----------------------------------------------------------------------------------
    var createNode = function(coord, pLine, pIdxNode, nodeColor) {
        nodeColor = nodeColor ? nodeColor : "#fff";
        //console.log("createNode pLine:: ", pLine);
        var circleSVG = nodeSVG.replace("{%fill}", nodeColor),
            icon = new H.map.Icon(circleSVG, {
                anchor: {
                    x: 4,
                    y: 4
                }
            }),
            marker = new H.map.Marker(coord, {
                /*min: 13,*/
                icon: icon,
                zIndex: 99999,
                draggable: true
            });

        marker.draggable = true;
        //console.log("circleSVG:: ", circleSVG, marker);


        if (pLine && marker && pIdxNode != undefined) {
            //console.log("pLine && currNode && pIdxNode:: ");
            marker.setData({
                polyline: pLine,
                pIdxNode: pIdxNode == "last" ? pLine.getGeometry().getPointCount() - 1 : pIdxNode
            });
        }

        if (pLine && pLine.getData) {
            var pLineData = pLine.getData();
            pLineData.nodeMarkers.addObject(marker);
            pLine.setData(pLineData);
        }

        //console.log("pLine.getParentGroup:: ", pLine.getParentGroup());



        var streamDragNode = Kefir.fromEvents(marker, 'drag');
        var streamDragStartNode = Kefir.fromEvents(marker, 'dragstart');
        var streamDragEndNode = Kefir.fromEvents(marker, 'dragend');
        var streamCtxNodeMenu = Kefir.fromEvents(marker, 'contextmenu');
        var streamLongPressNode = Kefir.fromEvents(marker, 'longpress');


        streamDragNode
            .onValue(function(v) {
                behavior.disable();

                var coord = map.screenToGeo(v.currentPointer.viewportX, v.currentPointer.viewportY),
                    coordPoint = new H.math.Point(v.currentPointer.viewportX, v.currentPointer.viewportY);
                nodeMarker = v.target,
                    nodeData = nodeMarker.getData(),
                    strip = pLine.getGeometry(),
                    pLinedata = pLine.getData(),
                    countNodes = strip.getPointCount(),
                    firstOrLast = (nodeData.pIdxNode == (countNodes - 1) || nodeData.pIdxNode == 0);

                nodeMarker.setPosition(coord);

                if (firstOrLast) {
                    editTool.plSet.forEach(function(grppLine, idx) {
                        var spLine = grppLine.getData().polyline,
                            selected = spLine.getData().selected;
                        if (spLine.getId() != pLine.getId() && selected && pLinedata.selected) {
                            var spStrip = spLine.getGeometry();
                            var countSpNodes = spStrip.getPointCount();
                            var firstSpNode = spStrip.extractPoint(0);
                            var lastSpNode = spStrip.extractPoint(countSpNodes - 1);
                            var firstSpNodePoint = map.geoToScreen(firstSpNode);
                            var lastSpNodePoint = map.geoToScreen(lastSpNode);
                            var findedNewCoord = false;
                            var distToLast = coordPoint.distance(lastSpNodePoint);
                            var distToFirst = coordPoint.distance(firstSpNodePoint);
                            var distTo = false;

                            if (distToLast <= distToFirst) {
                                findedNewCoord = lastSpNode;
                                distTo = distToLast;
                            } else {
                                findedNewCoord = firstSpNode;
                                distTo = distToFirst;
                            }

                            if (distTo <= 70) {
                                //console.log("lastSpNodePoint distance:: ", distTo, nodeData);
                                var secondNode = nodeData.pIdxNode == 0 ? 1 : nodeData.pIdxNode - 1;
                                var sampleStrip = new H.geo.Strip();
                                sampleStrip.pushPoint(strip.extractPoint(secondNode));
                                sampleStrip.pushPoint(findedNewCoord);

                                editTool.sampleStitchPLine.setGeometry(sampleStrip);
                                editTool.sampleStitchPLine.setVisibility(true);
                                editTool.findedNewStitchCoord = findedNewCoord;

                            } else {
                                editTool.sampleStitchPLine.setVisibility(false);
                                editTool.findedNewStitchCoord = false;
                            }


                        }
                    });
                }

                //console.log("DragNode drag:: ", v, nodeData);
                changeStripByChangeNode(coord, nodeData.pIdxNode, nodeData.polyline);
            });

        streamDragStartNode
            .onValue(function(v) {
                behavior.disable();

                var nodeMarker = v.target,
                    nodeData = nodeMarker.getData();

                if (!nodeData.oldCoord) {
                    nodeData.oldCoord = nodeMarker.getPosition();
                    //console.log("set nodeData.oldCoord");
                }


            });

        streamDragEndNode
            .onValue(function(v) {
                var nodeMarker = v.target,
                    nodeData = nodeMarker.getData(),
                    newCoord = editTool.findedNewStitchCoord;
                if (editTool.findedNewStitchCoord) {
                    editTool.sampleStitchPLine.setVisibility(false);
                    nodeMarker.setPosition(newCoord);
                    changeStripByChangeNode(newCoord, nodeData.pIdxNode, nodeData.polyline);
                    editTool.findedNewStitchCoord = false;
                }
                behavior.enable();
            });

        streamLongPressNode
            .onValue(function(v) {
                //console.log("streamLongPressNode::", v);
            });


        streamCtxNodeMenu
            .onValue(editTool.ctrlCtxNodeMenu.bind(marker));


        return marker;

    };

    //-------------------------------------------------------------------------------
    var loadPolyline = editTool.loadPolyline = function(pLine, name) {
        this.curPolyline = this.curPolyline || {
            status: "stop",
            strip: false,
            polyline: false
        };
        if (!pLine.getData()) {
            pLine.setData({});
        }
        var pLineData = pLine.getData(),
            strip = pLine.getGeometry(),
            countNodes = strip.getPointCount();

        if (pLineData.stmPlineCtxMenu) {
            return;
        }

        if (pLineData.nodeMarkers) {
            pLineData.nodeMarkers.removeAll();
        } else {
            pLineData.nodeMarkers = new H.map.Group({
                min: countNodes > 1000 ? 13 : 7
            });
        }
        console.log("pLineData:: ", pLineData);
        pLine.setData(pLineData)

        strip.eachLatLngAlt(function(lat, lng, alt, idx) {
            createNode(new H.geo.Point(lat, lng), pLine, idx);
        });
        //console.log("nodes are finished created!");

        var pLineGrp = new H.map.Group();
        pLineGrp.addObject(pLine);
        pLineGrp.setData({
            polyline: pLine
        });

        pLineGrp.addObject(pLineData.nodeMarkers);

        pLineData.name = name; //pLineData.attributes.WAY_REFERENCE;
        pLine.setData(pLineData);

        editTool.plSet.addObject(pLineGrp);

        this.curPolyline = false;

        ctrlPolylineEvents(pLine);
    };

    //-----------------------------------------------------------------------------------
    function changeStripByChangeNode(newCoord, idxNode, polyline) {
        //console.log("changeStripByChangeNode:: ", polyline);
        var pStrip = polyline.getGeometry(); //getStrip();
        pStrip.removePoint(idxNode);
        pStrip.insertPoint(idxNode, newCoord);

        polyline.setGeometry(pStrip);
    }

    //-----------------------------------------------------------------------------------
    function changeNodeColor(polyline, nodeColor) {
        //console.log("changeNodeColor:: ", polyline);
        var pData = polyline.getData(),
            nodeMarkers = pData.nodeMarkers;

        nodeMarkers.forEach(function(node) {
            //console.log("node:: ", node.getIcon());

            var circleSVG = nodeSVG.replace("{%fill}", nodeColor),
                icon = new H.map.Icon(circleSVG, {
                    anchor: {
                        x: 4,
                        y: 4
                    }

                });

            node.setIcon(icon);
        });
    }

    //-----------------------------------------------------------------------------------
    this.onPolygon = function(clb_fn) {
        clb_fn();
    };
    //-----------------------------------------------------------------------------------
    window.editTool.onUpdate = function(fn) {
        //console.log("onUpdate:: ", fn);
        if (!fn) {
            for (var i = 0; i < this.fns.length; i++) {
                this.fns[i]();
            }
        } else {
            this.fns = this.fns || [];
            this.fns.push(fn);
        }
    };


    //})();
    return window.editTool;
};