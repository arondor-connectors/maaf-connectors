function arenderjs_init(arenderjs_) {

	var query = window.location.search.substring(1); // on récupère les paramètres de l'url
	var qs = parse_query_string(query); // on parse les paramètres de l'url qui nous retourne le format du style {element: "2", id: "{2004D566-8..."  objectStoreId: "{4DCD4764-1...", objectType: "document"}
	
	arenderjs_.getDocumentLayout().getDocumentLayout(arenderjs_.getMasterDocumentId(),function(obj){
	
		documentLayouts=obj;

		var docId = documentLayouts.getChildren()[qs.element-1].getDocumentId(); // on récupère (via qs.element)  le numéro du content du document que l'on souhaite afficher.  Attention, on fait qs.element-1 car Arender commence à 0 et ViewOne à 1

		arenderjs_.askChangeDocument("ByDocumentId", docId)
	});
}

function parse_query_string(query) {
	  var vars = query.split("&");
	  var query_string = {};
	  for (var i = 0; i < vars.length; i++) {
		var pair = vars[i].split("=");
		// If first entry with this name
		if (typeof query_string[pair[0]] === "undefined") {
		  query_string[pair[0]] = decodeURIComponent(pair[1]);
		  // If second entry with this name
		} else if (typeof query_string[pair[0]] === "string") {
		  var arr = [query_string[pair[0]], decodeURIComponent(pair[1])];
		  query_string[pair[0]] = arr;
		  // If third or later entry with this name
		} else {
		  query_string[pair[0]].push(decodeURIComponent(pair[1]));
		}
	  }
	  return query_string;
}