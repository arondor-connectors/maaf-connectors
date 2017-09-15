function arenderjs_init(arenderjs_) {

    window.colorThumbs = function (jsonMap) {
        if (document.querySelector('.documentexplorer_treeview_thumbview') !== undefined &&
            document.querySelector('.thumblabel_container') !== undefined &&
            document.querySelector('.thumblabel thumblabel-odd') !== undefined) {
            var thumbs = document.getElementsByClassName("documentexplorer_treeview_thumbview");
            for (var i = 0; i < thumbs.length; i++) {
                var thumb0Container = thumbs[i].getElementsByClassName("thumblabel_container");
                if (thumb0Container[0] !== undefined &&
                    thumb0Container[0].getElementsByClassName("thumblabel thumblabel-odd")[0] !== undefined) {
                    var pages = thumb0Container[0].getElementsByClassName("thumblabel thumblabel-odd")[0].innerText;
                    if (pages.indexOf('/') !== -1) {
                        var page = pages.substr(0, pages.indexOf('/')).trim();
                        var realPage = page - 1;
                        if (jsonMap.hasOwnProperty(realPage.toString())) {
                            thumbs[i].style.backgroundColor = jsonMap[realPage.toString()]["color"];
                        }
                        else {
                            console.log("Page number " + page + " does not have any color associated");
                        }
                    }
                }
            }
        }
        else {
            console.log("Following CSS classes not found : documentexplorer_treeview_thumbview or " +
                "thumblabel_container or thumblabel thumblabel-odd");
        }
    };

    window.loadMergedDocument = function () {
        startLoadingEffect();
        var originalDocumentId = arenderjs_.getMasterDocumentId();

        if (originalDocumentId !== undefined && originalDocumentId !== '') {
            var reqGetJSONMap = new XMLHttpRequest();
            reqGetJSONMap.open('GET', 'getJSONColorMap.jsp?uuid=' + originalDocumentId, true);
            reqGetJSONMap.onreadystatechange = function (aEvt) {
                if (reqGetJSONMap.readyState === 4) {
                    if (reqGetJSONMap.status !== 200) {
                        console.log("Erreur durant la mise à jour du Statut en GED.");
                        stopLoadingEffect();
                    }
                    else {
                        var pagesDocIdAndColor = reqGetJSONMap.responseText;
                        var reqGetUUID = new XMLHttpRequest();
                        reqGetUUID.open('POST', 'getMergedDocumentWithAnnotationsUUID.jsp', true);
                        reqGetUUID.onreadystatechange = function (aEvt) {
                            if (reqGetUUID.readyState === 4) {
                                if (reqGetUUID.status !== 200 || reqGetUUID.responseText.trim() === "") {
                                    console.log("Erreur durant la récupération de l'UUID du document fusionne.");
                                    stopLoadingEffect();
                                }
                                else {
                                    var uuid = reqGetUUID.responseText.trim();
                                    loadColoredDocument(uuid, pagesDocIdAndColor);
                                }
                            }
                        };
                        reqGetUUID.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
                        reqGetUUID.send("uuid=" + originalDocumentId + "&pagesDocIdAndColor=" + encodeURIComponent(pagesDocIdAndColor.trim()));
                    }
                }
            };
            reqGetJSONMap.send(null);
        }
    };
    arenderjs_.registerAllAsyncModulesStartedEvent(function () {
        loadMergedDocument();
    });

    function loadColoredDocument(uuid, pagesDocIdAndColor) {
        arenderjs_.loadDocument("loadingQuery?uuid=" + uuid, function (id) {
            arenderjs_.openDocument(id);
            arenderjs_.registerCurrentDocumentChangeEvent(function (id, title, metadata) {
                stopLoadingEffect();
                var jsonColorMap = JSON.parse(pagesDocIdAndColor);
                colorThumbs(jsonColorMap);
                var picTree = document.querySelector('[id^="PicTree"]');
                picTree.addEventListener("scroll", function () {
                    colorThumbs(jsonColorMap);
                });
                picTree.addEventListener("animationend", function () {
                    colorThumbs(jsonColorMap);
                });
            });
        });
    }

    function stopLoadingEffect() {
        document.body.style.opacity = 1;
        document.getElementById("loading").style.visibility = "hidden";
        document.getElementById("loading").style.zIndex = -1;
    }

    function startLoadingEffect() {
        document.body.style.opacity = 0.5;
        document.getElementById("loading").style.visibility = "visible";
        document.getElementById("loading").style.zIndex = 5000;
    }
}