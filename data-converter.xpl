<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:array="http://www.w3.org/2005/xpath-functions/array" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" 
    xmlns:rd="http://www.rolanddreger.net" 
    exclude-inline-prefixes="rd xs" name="pipeline" version="3.0">

    <p:import href="lib.xpl"/>
    <p:input port="source" sequence="true"/>
    <p:output port="result" sequence="true" serialization="map{'indent':true()}"/>
    
    <!-- Settings -->
    <p:option name="mode" static="true" as="xs:string" select="'debug'" />
    
    <p:variable name="input-folder-path" select="'input'"/> <!-- Input folder path (realtive or absolute) -->
    <p:variable name="output-folder-path" select="'output'"/> <!-- Output folder path (realtive or absolute) -->
    
    <p:variable name="model" select="'gpt-3.5-turbo-1106'"/> <!-- 'gpt-3.5-turbo-1106' or 'gpt-4-1106-preview' -->
    <p:variable name="system-role" select="'You are an expert in the field of data conversion in the IT sector.'"/>
    <p:variable name="instructions" select="'Your task is to convert from YAML format to JSON format. Use for this task the Code Interpreter tool. Use the PyYAML and json package for the conversion. Use the option &quot;ensure_ascii=False&quot; for the json.dump() method. It is very important that no properties in YAML format are lost during this conversion and that the data is transferred to JSON format without any losses. The result is returned in JSON format. DO NOT add a description or explanation and only output the converted result. Take your time for this task and follow the instructions carefully step by step.'"/>
    <p:variable name="prompt" select="'Convert to JSON format.'"/>
    
    <p:variable name="input-file-format" select="'yaml'"/>
    <p:variable name="output-file-format" select="'json'"/>
    
    <p:variable name="base-uri" select="'https://api.openai.com/v1'"/>
    <p:variable name="assistant-id" select="'MY-ASSISTANT-ID'"/>
    
    <!-- Create an assistant at platform.openai.com/assistants -->
    
    <!-- Create thread -->
    <p:variable name="endpoint" select="'/threads'"/>
    <rd:build-empty-request-body/>
    <rd:send-api-request p:message="Create a new thread" method="POST">
        <p:with-option name="uri" select="concat($base-uri, $endpoint)"/>
    </rd:send-api-request>
    
    <!--
    <p:identity>
        <p:with-input>
            <p:inline content-type="application/json" expand-text="false">
                { "id" : "thread_ZioWYuwOPkxLBzzrtkq4FSSA" }
            </p:inline>
        </p:with-input>
    </p:identity>
    -->
    
    <p:variable name="thread-id" select="map:get(.,'id')"/>
    
    <!-- Get file list (input folder) -->
    <p:directory-list path="{$input-folder-path}" max-depth="1">
        <p:with-option name="include-filter" select="(concat('\.',$input-file-format,'$'))"/>
    </p:directory-list>
    
    <!-- Loop files -->
    <p:for-each name="data-file-loop">
        
        <p:with-input select="/c:directory/c:file"/>
        
        <!-- Load file -->
        <p:variable name="filename" select="/*/@name"/>
        <p:load message="Load file {$filename}" name="load" href="{$input-folder-path}/{$filename}" content-type="text/plain"/>
        
        <!-- Add message to thread -->
        <p:variable name="add-message-endpoint" select="concat('/threads/', $thread-id, '/messages')"/>
        <rd:build-add-message-request-body>
            <p:with-option name="content" select="."/>
        </rd:build-add-message-request-body>
        <rd:send-api-request p:message="Add message" method="POST">
            <p:with-option name="uri" select="concat($base-uri, $add-message-endpoint)"/>
        </rd:send-api-request>

        <!-- Create run -->
        <p:variable name="create-run-endpoint" select="concat('/threads/', $thread-id, '/runs')"/>
        <rd:build-create-run-request-body>
            <p:with-option name="assistant-id" select="$assistant-id"/>
        </rd:build-create-run-request-body>
        <rd:send-api-request p:message="Create run" method="POST">
            <p:with-option name="uri" select="concat($base-uri, $create-run-endpoint)"/>
        </rd:send-api-request>
   
        <!-- Waiting for run -->
        <p:variable name="run-id" select="map:get(.,'id')"/>
        <p:variable name="wait-run-endpoint" select="concat('/threads/', $thread-id, '/runs/', $run-id)"/>
        <rd:wait-for-run p:message="Waiting ..." base-uri="{$base-uri}" endpoint="{$wait-run-endpoint}"/>
        
        <!-- List messages -->
        <p:variable name="endpoint" select="'/threads/' || $thread-id || '/messages' "/>
        <rd:build-empty-request-body/>
        <rd:send-api-request p:message="Retrieve thread" method="GET">
            <p:with-option name="uri" select="concat($base-uri, $endpoint)"/>
        </rd:send-api-request>
        
        <!-- Convert JSON to XML  -->
        <p:cast-content-type>
            <p:with-option name="content-type" select="'application/xml'"/>
        </p:cast-content-type>
 
        <!-- Get content text -->
        <p:identity>
            <p:with-input select="/fn:map/fn:array/fn:map[fn:string[@key eq 'role'] eq 'assistant'][1]/fn:array[@key eq 'content']/fn:map/fn:map[@key eq 'text']/fn:string[@key eq 'value']/text()"/>
        </p:identity>
        
        <!-- Parse string as JSON -->
        <p:identity>
            <p:with-input select="parse-json(.)"/>
        </p:identity>
        
        <!-- Here comes the validation -->
        
        <!-- Store JSON files for debugging -->
        <p:store name="store-result-file" href="{$output-folder-path}/{$filename}.{$output-file-format}" serialization="map{'indent':true()}"/>
        
    </p:for-each>

    <!-- Delete thread -->
    <p:variable name="endpoint" select="'/threads/' || $thread-id"/>
    <rd:build-empty-request-body/>
    <rd:send-api-request p:message="Delete a thread" method="DELETE">
        <p:with-option name="uri" select="concat($base-uri, $endpoint)"/>
    </rd:send-api-request>
    
</p:declare-step>
