import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.junit.Assert;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by The ARender Team on 18/07/2017.
 */
public class testJSON
{
    @Test
    public void testParseMapJSON()
    {
        String expectedJSON = "{\"3\":\"#407e8a\",\"2\":\"#6dc7dc\",\"1\":\"#407e8a\",\"0\":\"#6dc7dc\",\"5\":\"#407e8a\",\"4\":\"#6dc7dc\"}";

        Map<String, String> colorMap = new HashMap<String, String>();
        colorMap.put("3", "#407e8a");
        colorMap.put("2", "#6dc7dc");
        colorMap.put("1", "#407e8a");
        colorMap.put("0", "#6dc7dc");
        colorMap.put("5", "#407e8a");
        colorMap.put("4", "#6dc7dc");

        Gson gson = new Gson();
        String json = gson.toJson(colorMap);
        Assert.assertEquals(expectedJSON, json);
    }

    @Test
    public void testParseAdvancedMapJSON()
    {
        String expectedJSON = "{\"0\":{\"docId\":\"/0/1\",\"color\":\"#407e8a\"},\"1\":{\"docId\":\"/0/2\",\"color\":\"#6dc7dc\"}}";

        JsonObject item1 = new JsonObject();
        item1.addProperty("docId", "/0/1");
        item1.addProperty("color", "#407e8a");

        JsonObject item2 = new JsonObject();
        item2.addProperty("docId", "/0/2");
        item2.addProperty("color", "#6dc7dc");

        JsonObject pageNumberItem = new JsonObject();
        pageNumberItem.add("0", item1);
        pageNumberItem.add("1", item2);

        Assert.assertEquals(expectedJSON, pageNumberItem.toString());
    }

    @Test
    public void testCreateJSon()
    {
        String expectedDocId0 = "b64_dXJsPS4uL3NhbXBsZXMvbWFpbFNpbXBsZS5tc2c=/0/0";
        String expectedDocId1 = "b64_dXJsPS4uL3NhbXBsZXMvbWFpbFNpbXBsZS5tc2c=/0/1";
        String expectedDocId2 = "b64_dXJsPS4uL3NhbXBsZXMvbWFpbFNpbXBsZS5tc2c=/0/2";
        String pagesColorAndDocId = "{\"0\":{\"docId\":\"" + expectedDocId0 + "\",\"color\":\"#6dc7dc\"},"
                + "\"1\":{\"docId\":\"" + expectedDocId1 + "\",\"color\":\"#407e8a\"},"
                + "\"2\":{\"docId\":\"" + expectedDocId2 + "\",\"color\":\"#6dc7dc\"}}";

        JsonObject jsonPagesColorAndDocId = new JsonParser().parse(pagesColorAndDocId).getAsJsonObject();
        JsonObject jsonObject0 = jsonPagesColorAndDocId.get("0").getAsJsonObject();
        Assert.assertEquals(expectedDocId0,jsonObject0.get("docId").getAsString());

        JsonObject jsonObject1 = jsonPagesColorAndDocId.get("1").getAsJsonObject();
        Assert.assertEquals(expectedDocId1,jsonObject1.get("docId").getAsString());

        JsonObject jsonObject2 = jsonPagesColorAndDocId.get("2").getAsJsonObject();
        Assert.assertEquals(expectedDocId2,jsonObject2.get("docId").getAsString());

    }

}
