<%@ page
        import="com.arondor.viewer.annotation.api.Annotation,
                com.arondor.viewer.annotation.exceptions.AnnotationCredentialsException,
                com.arondor.viewer.annotation.exceptions.AnnotationNotAvailableException,
                com.arondor.viewer.annotation.exceptions.AnnotationsNotSupportedException,
                com.arondor.viewer.annotation.exceptions.InvalidAnnotationFormatException,
                com.arondor.viewer.client.api.document.*,
                com.arondor.viewer.client.api.document.altercontent.AlterContentDescriptionMultiSplit,
                com.arondor.viewer.client.api.document.altercontent.AlterContentOperationException,
                com.arondor.viewer.client.api.document.altercontent.description.AlteredDocumentDescription,
                com.arondor.viewer.client.api.document.altercontent.description.SourcePageDescription,
                com.arondor.viewer.common.document.id.DocumentIdFactory,
                com.arondor.viewer.common.documentaccessor.DocumentAccessorByteArray,
                com.arondor.viewer.common.util.DependencyInjection,
                com.arondor.viewer.rendition.api.annotation.AnnotationAccessor,
                com.arondor.viewer.rendition.api.document.DocumentAccessor,
                com.arondor.viewer.rendition.api.document.DocumentAccessorSelector,
                com.arondor.viewer.rendition.api.document.DocumentService,
                com.arondor.viewer.server.servlet.ServletDocumentService,
                com.google.gson.JsonElement,
                com.google.gson.JsonObject,
                com.google.gson.JsonParser,
                org.apache.commons.lang3.SerializationUtils,
                org.apache.log4j.Logger,
                java.io.IOException,
                java.io.PrintWriter,
                java.io.StringWriter,
                java.util.ArrayList,
                java.util.List,
                java.util.Map"
        contentType="text/html; charset=ISO-8859-1"
        pageEncoding="ISO-8859-1" %>

<%
    Logger logger = Logger.getLogger("com.arondor.viewer.client.jsp.getMergedDocumentUUID");
    ServletDocumentService servletDocumentService = (ServletDocumentService) DependencyInjection
            .getBean("servletDocumentService");
    servletDocumentService.setCurrentSession(request);

    DocumentId registeredDocumentId = null;
    try
    {
        registeredDocumentId = servletDocumentService.parseURL(application, request);
        DocumentAccessor documentAccessor = servletDocumentService
                .getDocumentAccessor(registeredDocumentId, DocumentAccessorSelector.REGISTERED);

        DocumentLayout layout = servletDocumentService.getDocumentLayout(registeredDocumentId);
        if (layout instanceof DocumentContainer)
        {
            DocumentContainer documentContainer = (DocumentContainer) layout;

            List<DocumentId> sources = new ArrayList<DocumentId>();
            AlterContentDescriptionMultiSplit description = new AlterContentDescriptionMultiSplit();

            description.setDocumentDescriptions(new ArrayList<AlteredDocumentDescription>());
            AlteredDocumentDescription docDesc = new AlteredDocumentDescription();
            docDesc.setPageDescriptions(new ArrayList<SourcePageDescription>());
            description.getDocumentDescriptions().add(docDesc);
            recursiveBuildAlterDocumentDescription(documentContainer, sources, docDesc, servletDocumentService);

            DocumentId altered = servletDocumentService.alterDocumentContent(sources, description);
            DocumentAccessor source = servletDocumentService
                    .getDocumentAccessor(altered, DocumentAccessorSelector.RENDERED);
            DocumentAccessor targetAccessor = new DocumentAccessorByteArray(DocumentIdFactory.getInstance().generate(),
                    source.getInputStream());
            targetAccessor.setDocumentTitle(documentContainer.getDocumentTitle());
            servletDocumentService.loadDocumentAccessor(targetAccessor);
            servletDocumentService.getDocumentLayout(targetAccessor.getUUID());
            logger.info("Merging and working on accessor with documentId : " + targetAccessor.getUUID()
                    + " with merged altered id of: " + altered);

            // get the list of pages and their corresponding documentId (JSON like {"0":{"docId":"/0/0","color":"#6dc7dc"},"1":{"docId":"b64_...
            HttpServletResponseWrapper responseWrapper = getHttpServletResponseWrapper(response);
            request.getRequestDispatcher("getJSONColorMap.jsp").forward(request, responseWrapper);
            String pagesDocIdAndColor = responseWrapper.toString();

            List<Annotation> originalAnnotations = documentAccessor.getAnnotationAccessor().get();
            List<Annotation> newAnnotations = new ArrayList<Annotation>();
            for (Annotation annotation : originalAnnotations)
                newAnnotations.add(SerializationUtils.clone(annotation));

            JsonObject jsonPagesDocIdAndColor = new JsonParser().parse(pagesDocIdAndColor).getAsJsonObject();
            for (Annotation annotation : newAnnotations)
            {
                for (Map.Entry<String, JsonElement> pageNumber : jsonPagesDocIdAndColor.entrySet())
                {
                    String currentDocumentId = pageNumber.getValue().getAsJsonObject().get("docId").getAsString();
                    logger.debug("Current annotation documentId: " + annotation.getDocumentId());
                    if (annotation.getDocumentId() != null && annotation.getDocumentId().toString()
                            .equals(currentDocumentId))
                    {
                        logger.debug("Setting annotation " + annotation.getId() + " to page :" + annotation.getPage());
                        annotation.setPage(Integer.parseInt(pageNumber.getKey()));
                        annotation.setDocumentId(targetAccessor.getUUID());
                    }
                }
            }

            // Retrieve the documentAccessor that represent the merged of all the document
            AnnotationAccessor annotationAccessor = servletDocumentService.getAnnotationAccessorFactory()
                    .create(servletDocumentService, targetAccessor);
            targetAccessor.setAnnotationAccessor(annotationAccessor);
            logger.debug("Creating annotations on documentAccessor of Id: " + targetAccessor.getUUID()
                    + " and we will display document :" + targetAccessor.getUUID());
            targetAccessor.getAnnotationAccessor().create(newAnnotations);
            // Write UUID as response to the request (openExternalDocument.jsp behavior)
            out.write(targetAccessor.getUUID().toString());
        }
        else
        {
            throw(new DocumentFormatNotSupportedException("Document must be a multiContentDocument"));
        }
    }
    catch (DocumentNotAvailableException e)
    {
        logger.error("Document a decoupe indisponible");
    }
    catch (DocumentFormatNotSupportedException e)
    {
        logger.error("Format du document non gere");
    }
    catch (AlterContentOperationException e)
    {
        logger.error("Fusion du document impossible");
    }
    catch (AnnotationsNotSupportedException e)
    {
        logger.error("Annotations non supportees");
    }
    catch (AnnotationCredentialsException e)
    {
        logger.error("Annotation credentials invalide");
    }
    catch (InvalidAnnotationFormatException e)
    {
        logger.error("Format d'annotation invalide");
    }
    catch (AnnotationNotAvailableException e)
    {
        logger.error("Annotation not disponible");
    }
%>
<%!
    private Logger logger = Logger.getLogger("com.arondor.viewer.client.jsp.getMergedDocumentUUID");

    private void recursiveBuildAlterDocumentDescription(DocumentContainer documentContainer, List<DocumentId> sources,
            AlteredDocumentDescription docDesc, DocumentService documentService)
            throws DocumentNotAvailableException, DocumentFormatNotSupportedException
    {
        List<DocumentLayout> resolvedDocumentLayouts = new ArrayList<DocumentLayout>();
        resolveDocumentLayouts(documentContainer, documentService, resolvedDocumentLayouts);

        /*
         * First pass, resolve only DocumentPageLayout
         */
        for (DocumentLayout childDocumentLayout : resolvedDocumentLayouts)
        {
            if (childDocumentLayout instanceof DocumentPageLayout)
            {
                DocumentPageLayout childPageLayout = (DocumentPageLayout) childDocumentLayout;
                try
                {
                    logger.debug("Getting DocumentAccessor with documentId:" + childPageLayout.getDocumentId());
                    documentService.getDocumentAccessor(childPageLayout.getDocumentId(),
                            DocumentAccessorSelector.RENDERED);
                    for (int page = 0; page < childPageLayout.getPageCount(); page++)
                    {
                        docDesc.getPageDescriptions()
                                .add(new SourcePageDescription(childPageLayout.getDocumentId(), page));
                    }
                    sources.add(childPageLayout.getDocumentId());
                }
                catch (Exception e)
                {
                    logger.error("Cannot get Rendered DocumentAccessor having documentId: " + childPageLayout.getDocumentId());
                }
            }
            else if (childDocumentLayout instanceof DocumentContainer)
            {
                /*
                 * Nothing to do here, will be done during next pass.
                 */
            }
            else
            {
                throw new DocumentNotAvailableException(
                        "Resolved child document layout (id : " + childDocumentLayout.getDocumentId()
                                + ") not supported : " + childDocumentLayout.getClass().getName());
            }
        }
        /*
         * Second pass, resolve DocumentContainer children
         */
        for (DocumentLayout childDocumentLayout : resolvedDocumentLayouts)
        {
            if (childDocumentLayout instanceof DocumentContainer)
            {
                logger.debug("RecursiveBuildAlterDocumentDescription will be called for documentId " + childDocumentLayout.getDocumentId());
                DocumentContainer childDocumentContainer = (DocumentContainer) childDocumentLayout;
                recursiveBuildAlterDocumentDescription(childDocumentContainer, sources, docDesc,
                        documentService);
            }
        }
    }


    private void resolveDocumentLayouts(DocumentContainer documentContainer, DocumentService documentService,
            List<DocumentLayout> resolvedDocumentLayouts) throws DocumentNotAvailableException
    {
        for (DocumentLayout layout : documentContainer.getChildren())
        {
            DocumentLayout resolvedDocumentLayout = null;

            if (layout instanceof DocumentReference)
            {
                DocumentReference documentReference = ((DocumentReference)layout);
                resolvedDocumentLayout = resolveDocumentreferences(documentService, documentReference);
                if (resolvedDocumentLayout == null)
                    continue;
                try
                {
                    documentService
                            .getDocumentAccessor(resolvedDocumentLayout.getDocumentId(), DocumentAccessorSelector.RENDERED);
                    resolvedDocumentLayouts.add(resolvedDocumentLayout);
                }
                catch (Exception e)
                {
                    throw new DocumentNotAvailableException("Could not get DocumentAccessor having following documentId = " + resolvedDocumentLayout.getDocumentId());
                }
            }
            else if (layout instanceof DocumentContainer)
            {
                DocumentContainer childDocumentContainer = ((DocumentContainer)layout);
                resolveDocumentLayouts(childDocumentContainer, documentService, resolvedDocumentLayouts);
            }
        }
    }

    private DocumentLayout resolveDocumentreferences(DocumentService documentService, DocumentReference documentReference)
            throws DocumentNotAvailableException
    {
        DocumentLayout resolvedDocumentLayout;
        try
        {
            logger.debug("documentService.getDocumentLayout (" + documentReference.getDocumentId() +") having class=" + documentReference.getClass());
            resolvedDocumentLayout = documentService.getDocumentLayout(documentReference.getDocumentId());
        }
        catch (Exception e)
        {
            return null;
        }
        if (resolvedDocumentLayout == null)
        {
            throw new DocumentNotAvailableException(
                    "Could not resolve child document documentReference for id : " + documentReference.getDocumentId());
        }
        if (!documentReference.getDocumentId().equals(resolvedDocumentLayout.getDocumentId()))
        {
            throw new DocumentNotAvailableException(
                    "Invalid diverging DocumentId : Reference is : " + documentReference.getDocumentId()
                            + " but resolved to : " + resolvedDocumentLayout.getDocumentId());
        }
        return resolvedDocumentLayout;
    }

    private HttpServletResponseWrapper getHttpServletResponseWrapper(HttpServletResponse response)
    {
        return new HttpServletResponseWrapper(response)
        {
            private final StringWriter sw = new StringWriter();

            @Override public PrintWriter getWriter() throws IOException
            {
                return new PrintWriter(sw);
            }

            @Override public String toString()
            {
                return sw.toString();
            }
        };
    }
%>