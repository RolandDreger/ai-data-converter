<?xml version="1.0" encoding="UTF-8"?>
<p:library xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:array="http://www.w3.org/2005/xpath-functions/array" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:rd="http://www.rolanddreger.net" 
    version="3.0">
    
    <!-- Global Options -->
    <p:option name="api-key" as="xs:string" select="'your-api-key'" static="true" visibility="private" />
    
    <!-- Step: Build empty JSON map for http request body -->
    <p:declare-step type="rd:build-empty-request-body">
        
        <p:output port="result" primary="true" content-types="application/json"/>
        
        <p:identity>
            <p:with-input>
                <p:inline content-type="application/json" expand-text="false">{}</p:inline>
            </p:with-input>
        </p:identity>
        
    </p:declare-step>
    
    <!-- Build request body: Create thread -->
    <p:declare-step type="rd:build-add-message-request-body">
        
        <p:documentation>
            { 
                "role" : "user", 
                "content":"name: German\northographies:\n- autonym: Deutsch\n" 
            }   
        </p:documentation>
        
        <p:output port="result" primary="true" sequence="false" content-types="application/json"/>
        
        <p:option name="content" required="true"/>
        
        <!-- Request body (match with default namespace fn, e.g.fn:map) -->
        <p:identity>
            <p:with-input>  
                <p:inline>
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <string key="role">user</string>
                        <string key="content">{$content}</string>
                    </map>
                </p:inline>
            </p:with-input>
        </p:identity>
        
        <!-- Convert XML to JSON -->
        <p:cast-content-type>
            <p:with-option name="content-type" select="'application/json'"/>
        </p:cast-content-type>
        
    </p:declare-step>
    
    <!-- Build request body: Create run -->
    <p:declare-step type="rd:build-create-run-request-body">
        
        <p:documentation>
            { 
            'assistant_id': $assistant-id  
            }   
        </p:documentation>
        
        <p:output port="result" primary="true" sequence="false" content-types="application/json"/>
        
        <p:option name="assistant-id" required="true"/>
        
        <!-- Request body (match with default namespace fn, e.g.fn:map) -->
        <p:identity>
            <p:with-input>  
                <p:inline>
                    <map xmlns="http://www.w3.org/2005/xpath-functions">
                        <string key="assistant_id">{$assistant-id}</string>
                    </map>
                </p:inline>
            </p:with-input>
        </p:identity>
        
        <!-- Convert XML to JSON -->
        <p:cast-content-type>
            <p:with-option name="content-type" select="'application/json'"/>
        </p:cast-content-type>
        
    </p:declare-step>
    
    
    
    <!-- Step: OpenAI API request -->
    <p:declare-step type="rd:send-api-request" visibility="public">
        
        <p:documentation>
            input:   JSON for request body
            output:  JSON response
        </p:documentation>
        
        <p:input port="source" primary="true" sequence="true" content-types="application/json"/>
        <p:output port="result" primary="true" sequence="true" content-types="application/json"/>
        
        <p:option name="is-logging" static="true" select="false()" />
        
        <p:option name="uri" required="true"/>
        <p:option name="method" required="true"/>
        <p:option name="custom-headers" required="false" select="map {}"/>
        
        <!-- Request headers -->
        <p:variable name="headers" as="map(xs:string, xs:string)" select="map {
                'authorization': concat('Bearer ', $api-key),
                'content-type': 'application/json',
                'OpenAI-Beta': 'assistants=v1'
            }"/>
        
        <!-- API request -->
        <p:try name="try-catch-http-request">
            <p:output primary="true" pipe="report@http-request"/>
            <p:output primary="false" port="result" pipe="result@http-request"/>
            <p:http-request name="http-request">
                <p:with-option name="href" select="escape-html-uri($uri)"/>
                <p:with-option name="method" select="$method"/>
                <p:with-option name="headers" select="map:merge(($headers, $custom-headers))"/>
            </p:http-request>
            <p:catch name="catch">
                <p:cast-content-type content-type="application/json">
                    <p:with-input select="/c:errors/c:error/fn:map"/>
                </p:cast-content-type>
            </p:catch>
        </p:try>
        
        <!-- Response status and URI -->
        <p:variable name="status-code" select="map:get(., 'status-code')"/>
        <p:variable name="base-uri" select="map:get(., 'base-uri')"/>
        
        <!-- Response data -->
        <p:identity>
            <p:with-input pipe="result@try-catch-http-request"/>
        </p:identity>
        
        <!-- Log response status -->
        <p:identity use-when="$is-logging" message="Response status: {$status-code} URI: {$base-uri}"/>
    </p:declare-step>
    
    
    <!-- Step: Wait until the run is completed  -->
    <p:declare-step type="rd:wait-for-run">
        
        <p:output port="result" primary="true" sequence="true"/>
        <p:option name="base-uri" required="true"/>
        <p:option name="endpoint" required="true"/>
        
        <rd:build-empty-request-body/>
        <rd:send-api-request method="GET">
            <p:with-option name="uri" select="concat($base-uri, $endpoint)"/>
        </rd:send-api-request>
        
        <p:variable name="run-status" select="map:get(.,'status')"/>
        
        <p:if test="$run-status ne 'completed'">
            <rd:wait-for-run base-uri="{$base-uri}" endpoint="{$endpoint}"/>
        </p:if>
        
    </p:declare-step>
    
</p:library>
