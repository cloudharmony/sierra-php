{ldelim}
  "swagger": "2.0",
  "info": {ldelim}
    "title": "{if $router->_settings.name}{$router->_settings.name}{else}{$Controller->getAppName()} {$api_resources->getString('api')}{/if}",
    {if $router->_settings.description}"description": "{$router->_settings.description}",{/if}
    {if $router->_settings.terms_of_service}"termsOfService": "{$router->_settings.terms_of_service}",{/if}
    {if $router->_settings.contact_name || $router->_settings.contact_email || $router->_settings.contact_url}
    "contact": {ldelim}
      {assign var=started value=0}
      {if $router->_settings.contact_name}"name": "{$router->_settings.contact_name}"{assign var=started value=1}{/if}
      {if $router->_settings.contact_email}{if $started}, {/if}"email": "{$router->_settings.contact_email}"{assign var=started value=1}{/if}
      {if $router->_settings.contact_url}{if $started}, {/if}"url": "{$router->_settings.contact_url}"{/if}
    {rdelim},
    {/if}
    {if $router->_settings.license_name || $router->_settings.license_url}
    "license": {ldelim}
      {if $router->_settings.license_name}"name": "{$router->_settings.license_name}"{/if}
      {if $router->_settings.license_url}{if $router->_settings.license_name}, {/if}"url": "{$router->_settings.license_url}"{/if}
    {rdelim},
    {/if}

    "version": "{if $router->_settings.api_version}{$router->_settings.api_version}{else}1.0{/if}"
  {rdelim},
  {if $router->_settings.external_docs_url}
  "externalDocs": {ldelim}
    {if $router->_settings.external_docs_description}"description": "{$router->_settings.external_docs_description|replace:'\\':'\\\\'|replace:'"':'\"'}",{/if}
    "url": "{$router->_settings.external_docs_url}"
  {rdelim},
  {/if}
  "host": "{$router->_settings.url_hostname}",
  "basePath": "{$router->_settings.url_resource}",
  "schemes": [
    "{$router->_settings.url_proto}"
  ],
{assign var=hasCsv value=0}
{foreach from=$router->_methods item=method}
{assign var=last_method value=$method.name}
{if $method.return.entity && $method.return.csv_method}{assign var=hasCsv value=1}{/if}
{/foreach}
  "produces": [
{if $hasCsv}
    "text/csv",
{/if}
    "application/json"
  ],
  "paths": {ldelim}
{foreach from=$router->_methods item=method}{if !$method.doc_hidden}{assign var=last_method value=$method.name}{/if}{/foreach}
{assign var=added_methods value=' '}
{foreach from=$router->_methods item=match}
{foreach from=$router->_methods item=method}{if !$method.doc_hidden && $method.route.full eq $match.route.full}{foreach from=$method.http_methods key=i item=http}{assign var=last_match value=$http}{/foreach}{/if}{/foreach}
{assign var=started value=0}
{foreach from=$router->_methods item=method}
{assign var=check value=$method.route.full|cat:'-'}
{if !$method.doc_hidden && $method.route.full eq $match.route.full && !$added_methods|strpos:$check}
{foreach from=$method.http_methods key=i item=http}{assign var=last_http value=$http}{/foreach}
    {if $started}, {else}"{$method.route.fixed}{foreach from=$method.route.placeholders item=placeholder}/{ldelim}{$placeholder}{rdelim}{/foreach}": {ldelim}{/if}

{foreach from=$method.http_methods key=i item=http}
{assign var=consumesFormData value=0}
      "{$http|lower}": {ldelim}
{if $method.tags}
        "tags": [{foreach from=$method.tags item=tag}{assign var=last_tag value=$tag}{/foreach}{foreach from=$method.tags item=tag}"{$tag}"{if $tag neq $last_tag}, {/if}{/foreach}],
{/if}
        "summary": "{if $method.http_method_summaries[$i]}{$method.http_method_summaries[$i]}{else}{$method.name}{/if}",
        "description": "{$method.name}{if $method.description}: {$method.description|replace:'\\':'\\\\'|replace:'"':'\"'}{/if}",
        "operationId": "{$method.http_method_nicknames[$i]}",
{if $method.return.entity && $method.return.csv_method}
        "produces": [
          "text/csv"
        ],
{/if}
        "parameters": [
{assign var=last_param value=0}
{foreach from=$method.params key=name item=param}{assign var=last_param value=$name}{/foreach}
{if $method.return.entity}
{assign var=entity value=$router->getEntities($method.return.type)}
{if $entity.hasDate && !$method.skip_date_params}
          {ldelim}
            "name": "format-date",
            "in": "{if $http eq 'GET'}query{else}formData{/if}",
            "description": "{$api_resources->getString('api.formatDate')}",
            "required": false,
            "type": "string",
            "default": "{$method.format_time}"
          {rdelim},
          {ldelim}
            "name": "use-date-object",
            "in": "{if $http eq 'GET'}query{else}formData{/if}",
            "description": "{$api_resources->getString('api.useDateObject')}",
            "required": false,
            "type": "boolean",
            "default": false
          {rdelim}{if $last_param},{/if}

{/if}
{if !$method.skip_callback_param}
          {ldelim}
            "name": "callback",
            "in": "{if $http eq 'GET'}query{else}formData{/if}",
            "description": "{$api_resources->getString('api.callback')}",
            "required": false,
            "type": "string"
          {rdelim}{if $last_param},{/if}
{/if}

{/if}
{foreach from=$method.params key=name item=param}
{assign var=type value=$param.type}
          {ldelim}
            "name": "{$name}",
{if $param.description}
            "description": "{$param.description|replace:'\\':'\\\\'|replace:'"':'\"'}",
{/if}
            "required": {if $param.required || $param.placeholder}true{else}false{/if},
            "type": "{if $param.array}array{else}{if $type eq 'int'}integer{elseif $type eq 'float'}number{elseif $type eq 'boolean' || $type eq 'bool'}boolean{else}string{/if}{/if}",
{if $type eq 'date' || $type eq 'timestamp'}
            "format": "{if $type eq 'date'}date{else}dateTime{/if}",
{/if}
{if $type eq 'boolean' || $type eq 'bool' || (!$param.options && $param.default && $param.default neq 'NULL' && $param.default neq 'null')}
            "default": {if $type eq 'string'}"{$param.default}"{elseif $type eq 'boolean' || $type eq 'bool'}{if $param.default}true{else}false{/if}{elseif !is_object($param.default)}{$param.default}{else}null{/if},
{/if}
{if $param.options}
{if $param.array}
            "items": {ldelim}
              "type": "{if $type eq 'int'}integer{elseif $type eq 'float'}number{else}string{/if}",{/if}
{foreach from=$param.options item=option}{assign var=last_option value=$option}{/foreach}
{if $param.array}  {/if}            "enum": [{foreach from=$param.options item=option}"{$option}"{if $option neq $last_option}, {/if}{/foreach}]{if !$param.array},{/if}
{if $param.array}

            {rdelim},
{/if}
{elseif $param.array}
            "items": {ldelim}
              "type": "{if $type eq 'int'}integer{elseif $type eq 'float'}number{else}string{/if}"
            {rdelim},
{/if}
            "in": "{if $param.placeholder}path{elseif $http eq 'GET'}query{else}{assign var=consumesFormData value=1}formData{/if}"

          {rdelim}{if $name neq $last_param},{/if}

{/foreach}
        ],
{if $consumesFormData}
        "consumes": [
          "application/x-www-form-urlencoded",
          "multipart/form-data"
        ],
{/if}
{assign var=started value=0}
{assign var=type value=$method.return.type}
{foreach from=$method.status_codes_num key=code item=description}{if !$method.status_doc_skip[$code]}{assign var=last_code value=$code}{/if}{/foreach}
        "responses": {ldelim}
{foreach from=$method.status_codes_num key=code item=description}
{if !$method.status_doc_skip[$code]}
          "{$code}": {ldelim}
{if $code lt 300}
            "schema": {ldelim}
              "{if $method.return.array || !$method.return.entity}type{else}$ref{/if}": "{if $method.return.array}array{elseif $method.return.entity}#/definitions/{$method.return.type_label}{elseif $type eq 'int'}integer{elseif $type eq 'float'}number{elseif $type eq 'boolean' || $type eq 'bool'}boolean{elseif $type eq 'void'}void{else}string{/if}"{if $method.return.array},{/if}
{if $method.return.array}
              "items": {ldelim}
                "{if $method.return.entity}$ref{else}type{/if}": "{if $method.return.entity}#/definitions/{$method.return.type_label}{elseif $type eq 'int'}integer{elseif $type eq 'float'}number{elseif $type eq 'boolean' || $type eq 'bool'}boolean{elseif $type eq 'void'}void{else}string{/if}"
              {rdelim}
{/if}
            {rdelim},
{/if}
            "description": "{if $description}{$description}{else}{$api_resources->getString('api.noErrorDescription')}{/if}"
          {rdelim}{if $code neq $last_code},{/if}
{/if}
{/foreach}
        {rdelim}
      {rdelim}{if $http neq $last_http},{/if}
{/foreach}
{assign var=started value=1}
{/if}
{/foreach}
{assign var=added_methods value=$added_methods|cat:$match.route.full|cat:'-'}
  {if $started}{rdelim}{if $match.name neq $last_method},{/if}{/if}
{/foreach}
  {rdelim},
  "definitions": {ldelim}
{foreach from=$router->getEntities() key=type item=entity}{assign var=last_entity value=$entity.type_label}{/foreach}
{foreach from=$router->getEntities() key=type item=entity}
    "{$entity.type_label}": {ldelim}
      "type": "object",
{if $entity.description}
      "description": "{$entity.description|replace:'\\':'\\\\'|replace:'"':'\"'}",
{/if}
{assign var=last_required value=0}
{foreach from=$entity.attributes key=name item=attribute}{if $attribute.required}{assign var=last_required value=$name}{/if}{assign var=last_attribute value=$name}{/foreach}
{if $last_required}
      "required": [
{foreach from=$entity.attributes key=name item=attribute}
{if $attribute.required}
        "{$name}"{if $name neq $last_required},{/if}

{/if}
{/foreach}
      ],
{/if}
      "properties": {ldelim}
{foreach from=$entity.attributes key=name item=attribute}
{assign var=type value=$attribute.type}
        "{$name}": {ldelim}
{if $attribute.description}
          "description": "{$attribute.description|replace:'\\':'\\\\'|replace:'"':'\"'}",
{/if}
{if $type eq 'date' || $type eq 'timestamp'}
          "format": "{if $type eq 'date'}date{else}dateTime{/if}",
{/if}
{if $attribute.default || $type eq 'boolean' || $type eq 'bool'}
          "default": {if $type eq 'string'}"{$attribute.default}"{elseif $type eq 'boolean' || $type eq 'bool'}{if $attribute.default}true{else}false{/if}{elseif !is_object($attribute.default)}{$attribute.default}{else}null{/if},
{/if}
{if $attribute.options}
{foreach from=$attribute.options key=option item=label}{assign var=last_option value=$option}{/foreach}
          "enum": [{foreach from=$attribute.options key=option item=label}"{$option}"{if $option neq $last_option}, {/if}{/foreach}],
{/if}
{if $attribute.array || !$attribute.entity}
          "type": "{if $attribute.array}array{elseif $type eq 'int'}integer{elseif $type eq 'float'}number{elseif $type eq 'boolean' || $type eq 'bool'}boolean{elseif $type eq 'void'}void{elseif !$attribute.entity}string{/if}"{if $attribute.array},{/if}
{if $attribute.array}
          "items": {ldelim}
            "{if $attribute.entity}$ref{else}type{/if}": "{if $attribute.entity}#/definitions/{$attribute.type_label}{elseif $type eq 'int'}integer{elseif $type eq 'float'}number{elseif $type eq 'boolean' || $type eq 'bool'}boolean{elseif $type eq 'void'}void{else}string{/if}"
          {rdelim}
{/if}
{else}
          "$ref": "#/definitions/{$attribute.type_label}"
{/if}
        {rdelim}{if $name neq $last_attribute},{/if}

{/foreach}
      {rdelim}
    {rdelim}{if $entity.type_label neq $last_entity},{/if}

{/foreach}
  {rdelim}
{rdelim}
