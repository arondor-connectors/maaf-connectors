<%@ page
        import="com.arondor.viewer.client.api.document.*,
                com.arondor.viewer.common.util.DependencyInjection,
                com.arondor.viewer.server.servlet.ServletDocumentService,
                com.google.gson.JsonObject,
                java.io.IOException"
        language="java" contentType="text/html; charset=ISO-8859-1"
        pageEncoding="ISO-8859-1" %>

<%
    ServletDocumentService documentService = (ServletDocumentService) DependencyInjection
            .getBean("servletDocumentService");
    documentService.setCurrentSession(request);

    DocumentId documentId = documentService.parseURL(application, request);

    // Map that will contains a list of pageNumber (key) and associated color and documentIdSuffix
    JsonObject jsonPagesDetails = new JsonObject();

    // Fetch documentLayout ot associate page with background color
    DocumentLayout documentLayout = documentService.getDocumentLayout(documentId);
    boolean useFirstColor = true;
    int pageNumber = 0;
    Args args = new Args(useFirstColor, pageNumber);
    fillJSONMap(documentService, documentLayout, jsonPagesDetails, args);

    // Write UUID in JSON ********************
    out.write(jsonPagesDetails.toString());

%><%! public static final String COLOR_2 = "#407e8a";
    public static final String COLOR_1 = "#6dc7dc";

    private String getColor(boolean useFirstColor)
    {
        return (useFirstColor) ? COLOR_1 : COLOR_2;
    }

    private Args fillJSONMap(ServletDocumentService documentService, DocumentLayout documentLayout,
            JsonObject jsonPagesDetails, Args args)
            throws DocumentFormatNotSupportedException, DocumentNotAvailableException, IOException
    {
        if (documentLayout instanceof DocumentPageLayout)
        {
            DocumentPageLayout documentPageLayout = (DocumentPageLayout) documentLayout;
            for (int i = 0; i < documentPageLayout.getPageCount(); i++)
            {
                JsonObject item1 = new JsonObject();
                item1.addProperty("docId", documentPageLayout.getDocumentId().toString());
                item1.addProperty("color", getColor(args.isUseFirstColor()));

                jsonPagesDetails.add(args.getPageNumber() + "", item1);
                args.setPageNumber(args.getPageNumber() + 1);
            }
            args.setUseFirstColor(!args.isUseFirstColor());
            return args;
        }
        else if (documentLayout instanceof DocumentContainer)
        {
            DocumentContainer documentContainer = (DocumentContainer) documentLayout;
            for (DocumentLayout subDocumentLayout : documentContainer.getChildren())
            {
                args = fillJSONMap(documentService, subDocumentLayout, jsonPagesDetails, args);
            }
        }
        else if (documentLayout instanceof DocumentReference)
        {
            DocumentReference documentReference = (DocumentReference) documentLayout;
            DocumentLayout resolved = documentService.getDocumentLayout(documentReference.getDocumentId());
            fillJSONMap(documentService, resolved, jsonPagesDetails, args);
        }
        else
        {
            throw new DocumentFormatNotSupportedException("Invalid class : " + documentLayout.getClass().getName());
        }
        return args;
    }

    private class Args
    {
        private boolean useFirstColor;

        private int pageNumber;

        public Args(boolean useFirstColor, int pageNumber)
        {
            this.useFirstColor = useFirstColor;
            this.pageNumber = pageNumber;
        }

        public boolean isUseFirstColor()
        {
            return useFirstColor;
        }

        public int getPageNumber()
        {
            return pageNumber;
        }

        public void setUseFirstColor(boolean useFirstColor)
        {
            this.useFirstColor = useFirstColor;
        }

        public void setPageNumber(int pageNumber)
        {
            this.pageNumber = pageNumber;
        }
    }
%>