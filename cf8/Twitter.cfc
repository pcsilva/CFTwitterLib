<!---
 
 CFTwitterLib - ColdFusion Twitter Lib is implementatio of Twitter API.
 
 Copyright (c) <2009> Pedro Claudio <pcsilva@gmail.com> 
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses>.
 
 --->
<cfcomponent displayname="Twitter" alias="Twitter">

    <cfproperty name="http_status" type="numeric" >
    <cfproperty name="last_api_call" type="string" >
    <cfproperty name="application_source" type="string" >
    <cfproperty name="userid" type="string" >
    <cfproperty name="screenname" type="string" >
    <cfproperty name="password" type="string" >
    <cfproperty name="My" type="struct" >
    <cfproperty name="remaining_hits" type="numeric" >
    <cfproperty name="reset_time" type="date" >
    <cfproperty name="hourly_limit" type="numeric" >
    <cfproperty name="version" type="string" >
	<cfproperty name="nextResetHits" type="date">
	<cfproperty name="currentStatus" type="string" >

    <cffunction name="init" access="public" returntype="Twitter">
      <cfargument name="username" type="String" required="true" >
      <cfargument name="pass" type="String" required="true" >
		<cfset Variables.http_status        = 401 >
		<cfset Variables.last_api_call      = "">
		<cfset Variables.application_source = "cftwitterlib">
		<cfset Variables.screenname         = arguments.username>
		<cfset Variables.password           = arguments.pass>
		<cfset Variables.version            = "9.2">
		<cfset Variables.My                 = StructNew()>
		<cfset Variables.currentStatus             = 'initialized'>
		<cfset Variables.nextResetHits         = DateAdd('h',1,now())>
		<cfset setRealRemainingHits()>
		<cfset setUserid(arguments.username)>
      <cfreturn this >
    </cffunction>
    
	<cffunction name="setRealRemainingHits" access="private" returntype="void"> 
		<cfhttp url='http://twitter.com/account/rate_limit_status.json' />
		<cfset Struct                   = DeserializeJSON(cfhttp.FileContent)>
		<cfset Variables.reset_time     = CreateODBCDateTime(Struct.reset_time)>
		<cfset Variables.remaining_hits = Struct.remaining_hits>
	</cffunction>     
    
    
	<cffunction name="isConnectionOpen" access="private" returntype="boolean"> 
		<cfset var ret = true>
		<cfset Variables.currentStatus = 'active'>
		<cfif Variables.remaining_hits lt 1 >
			<cfif DateDiff('h',Variables.nextResetHits,now()) gt 0 >
				<cfset Variables.nextResetHits = DateAdd('h',1,now())>
				<cfset setRealRemainingHits() >
				<cfif Variables.remaining_hits lt 1 >
					<cfset Variables.currentStatus = 'limit hits exceeded' >
					<cfset ret = false >
				</cfif>
			<cfelse>
				<cfset Variables.currentStatus = 'limit hits exceeded' >
				<cfset ret = false >
			</cfif>
		<cfelse>
			<cfset Variables.remaining_hits=Variables.remaining_hits-1>
		</cfif>
		<cfreturn ret>
	</cffunction>    
    
    <cffunction name="setUserid" access="private" output="false" returntype="void">
      <cfargument name="username" type="String" required="true" >
      <cfset var temp = '' >
      <cftry>
        <cfset temp 	 = xmlparse(showUser(username,'xml')) >
        <cfif StructKeyExists(temp,'user')>
          <cfset userid = temp.user.id.xmltext >
        </cfif>
        <cfcatch type="coldfusion.xml.XmlProcessException">
        </cfcatch>
      </cftry>
    </cffunction>
    
    <cffunction name="getUserid" access="public" output="false" returntype="string">
      <cfset var temp = '' >
      <cfif Not Len(Trim(userid))>
        <cfset setUserid(screenname) >
      </cfif>
      <cfreturn userid>
    </cffunction>

    <cffunction name="getReset_time" access="public" output="false" returntype="date">
      <cfreturn reset_time>
    </cffunction>
    
    <cffunction name="getHourly_limit" access="public" output="false" returntype="numeric">
      <cfreturn hourly_limit>
    </cffunction>
    
    <cffunction name="getRemaining_hits" access="public" output="false" returntype="numeric">
      <cfreturn remaining_hits>
    </cffunction>
    
    <cffunction name="getUsername" access="public" output="false" returntype="string">
      <cfreturn screenname>
    </cffunction>
    
    <cffunction name="getVersion" access="public" output="false" returntype="string">
      <cfreturn "7.0" >
    </cffunction>
    
    <cffunction name="lastStatusCode" access="public" output="false" returntype="numeric">
      <cfreturn http_status >
    </cffunction>
    
    <cffunction name="lastAPICall" access="public" output="false" returntype="string">
      <cfreturn last_api_call >
    </cffunction>
    
    <cffunction name="execute" access="private" returntype="string">
      <cfargument name="uriBase" type="String" required="true" >
      <cfargument name="require_credentials" type="Boolean" required="false" default="false" >
      <cfargument name="http_post" type="Boolean" required="false" default="false" >
      <cfargument name="path" type="string" required="false" default="" >
      <cfset var contentFile = "Connection Timeout" >
      <cfset var methodType = 'get' >
      <cfset var pass = '' >
      <cfset var user = '' >
      <cfif isConnectionOpen()>
	      <cfif arguments.http_post>
	        <cfset methodType = 'post' >
	      </cfif>
	      <cfif arguments.require_credentials>
	        <cfset pass = password >
	        <cfset user = screenname >
	      </cfif>
	      <cftry>
	        <cfhttp username="#user#" password="#pass#" timeout="5" method="#methodType#" resolveURL="yes" url="#arguments.uriBase#">
	          <cfif methodType eq 'post'>
	            <cfhttpparam type="formfield" name="source" value="cftwitterlib">
	            <cfif Len(Trim(arguments.path)) >
	              <cfhttpparam type="file" name="image" file="#arguments.path#">
	            </cfif>
	          </cfif>
	        </cfhttp>
	        <cfset http_status = ListFirst(cfhttp.StatusCode, ' ') >
	        <cfset last_api_call = arguments.uriBase >
	        <cfset contentFile = cfhttp.Filecontent >
	        <cfset remaining_hits = remaining_hits - 1 >
	        <cfcatch type="coldfusion.runtime.RequestTimedOutException">
				<cfset http_status = 401 >
	            <cfset remaining_hits = 0 >
	            <cfset reset_time= dateAdd("h",1,now()) >
	        </cfcatch>
	      </cftry>
	  </cfif>
      <cfreturn contentFile >
    </cffunction>
    
    <cffunction name="buildURL" access="private" output="false" returntype="string">
      <cfargument name="method" type="String" required="true" >
      <cfargument name="format" type="String" required="true" >
      <cfargument name="options" type="Struct" required="false" default="#StructNew()#" >
      <cfargument name="prefix" type="string" required="false" default="" >
      <cfset var request = "http://#arguments.prefix#twitter.com/#arguments.method#.#arguments.format#" >
      <cfset var key = "" >
      <cfset var values = "" >
      <cfloop collection="#arguments.options#" item="key">
        <cfset values = ListAppend(values,'#lcase(key)#=#arguments.options[key]#','&') >
      </cfloop>
      <cfset request = "#request#?#values#" >
      <cfreturn request >
    </cffunction>
    
    
    <!--- --->
    <!--- Search API Methods --->
    <!--- --->
    
    
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-weekly --->
    <cffunction name="getTrendsWeekly" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfset var uriBase = buildURL('trends/weekly', 'json',arguments.options,'search.') >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-daily --->
    <cffunction name="getTrendsDaily" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfset var uriBase = buildURL('trends/daily', 'json',arguments.options,'search.') >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-current --->
    <cffunction name="getTrendsCurrent" access="public" output="false" returntype="string">
      <cfargument name="exclude" default="true" required="false" type="boolean" >
      <cfset var excludetag = "" / >
      <cfif arguments.exclude>
        <cfset excludetag = "?exclude=hashtags" / >
      </cfif>
      <cfreturn execute("http://search.twitter.com/trends/current.json#excludetag#") >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends --->
    <cffunction name="getTrends" access="public" output="false" returntype="string">
      <cfreturn execute("http://search.twitter.com/trends.json") >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-search --->
    <cffunction name="search" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfargument name="format" type="string" required="false" default="atom" >
      <cfset var uriBase = buildURL('search', arguments.format,arguments.options,'search.') >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    
    <!--- --->
    <!--- REST API Methods --->
    <!--- --->
    
    
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-help%C2%A0test --->
    <cffunction name="test" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" default="json" required="false" >
      <cfset var uriBase = buildURL('help/test/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
	
	<!--- Trends Location Methods --->
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-trends-location --->
    <cffunction name="trendsLocation" access="public" output="false" returntype="string">
      <cfargument name="woeid" type="numeric" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
	  <cfset var uriBase = buildURL('1/trends/#arguments.woeid#', arguments.format,StructNew(),"api.") >
      <cfreturn execute(uriBase,true) >
    </cffunction>

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-trends-available --->
    <cffunction name="trendsAvailable" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
	  <cfset var uriBase = buildURL('1/trends/available', arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase) >
    </cffunction>    
    

	<!--- Saved Searches Methods --->    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-destroy --->
    <cffunction name="searchesDestroy" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('saved_searches/destroy/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-create --->    
    <cffunction name="searchesCreate" access="public" output="false" returntype="string">
      <cfargument name="query" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      	<cfset var uriBase = "">
		<cfset var options = StructNew() >
        <cfset options['query'] = arguments.query >
		<cfset uriBase = buildURL('saved_searches/create', arguments.format,options) >
        <cfreturn execute(uriBase, true, true) >
    </cffunction>

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-show --->
    <cffunction name="searchesShow" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('saved_searches/show/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    
	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches --->
    <cffunction name="searchesSaved" access="public" output="false" returntype="string">
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('saved_searches', arguments.format) >
      <cfreturn execute(uriBase, true) >
    </cffunction>


    <!--- Spam Reporting Methods --->
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-report_spam --->
    <cffunction name="reportingSpam" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('report_spam', arguments.format, arguments.options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>	
    
    <!---  Block Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0destroy --->
    <cffunction name="destroyBlock" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('blocks/destroy/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0create --->
    <cffunction name="createBlock" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('blocks/create/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Notification Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0leave --->
    <cffunction name="leave" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('notifications/leave/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0follow --->
    <cffunction name="follow" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('notifications/follow/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Favorite Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0destroy --->
    <cffunction name="destroyFavorite" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('favorites/destroy/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0create --->
    <cffunction name="createFavorite" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('favorites/create/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites --->
    <cffunction name="getFavorites" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" default="" required="false" >
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" default="json" required="false" >
      <cfset var uriBase = "" >
      <cfif Len(Trim(arguments.id))>
        <cfset uriBase = buildURL('favorites/#arguments.id#', arguments.format) >
        <cfelse>
        <cfset uriBase = buildURL('favorites', arguments.format) >
      </cfif>
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Account Methods --->
    <!--- Parameters: (image) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_image --->
    <cffunction name="updateProfileImageBackground" access="public" output="false" returntype="string">
      <cfargument name="path" type="string" required="true" >
      <cfargument name="title" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['title'] = arguments.title >
      <cfset uriBase = buildURL('account/update_profile_background_image', arguments.format,options) >
      <cfreturn execute(uriBase, true, true,arguments.path) >
    </cffunction>
    
    <!---  Parameters: (image) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_image --->
    <cffunction name="updateProfileImage" access="public" output="false" returntype="string">
      <cfargument name="path" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('account/update_profile_image', arguments.format) >
      <cfreturn execute(uriBase, true, true,arguments.path) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile --->
    <cffunction name="updateProfile" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('account/update_profile', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_colors --->
    <cffunction name="updateProfileColors" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('account/update_profile_colors', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_delivery_device--->
    <cffunction name="updateDeliveryDevice" access="public" output="false" returntype="string">
      <cfargument name="device" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['device'] = arguments.device >
      <cfset uriBase = buildURL('account/update_delivery_advice', arguments.format,options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0end_session --->
    <cffunction name="endSession" access="public" output="false" returntype="string">
      <cfargument name="format" type="string" default="json" required="false" >
      <cfset var uriBase = buildURL('account/end_session', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0rate_limit_status --->
    <cffunction name="rateLimitStatus" access="public" output="false" returntype="string">
      <cfargument name="allusers" type="boolean" default="true" required="false" >
      <cfargument name="format" type="string" default="json" required="false" >
      <cfset var uriBase = buildURL('account/rate_limit_status', arguments.format) >
      <cfreturn execute(uriBase, arguments.allusers) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0verify_credentials --->
    <cffunction name="verifyCredentials" access="public" output="false" returntype="string">
      <cfargument name="format" type="string" default="json" required="false" >
      <cfset var uriBase = buildURL('account/verify_credentials', arguments.format) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Social Graph Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-followers%C2%A0ids --->
    <cffunction name="getFollowerIDs" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('followers/ids', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friends%C2%A0ids --->
    <cffunction name="getFriendIDs" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('friends/ids', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Friendship Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-exists --->
    <cffunction name="friendshipExists" access="public" output="false" returntype="string">
      <cfargument name="user_a" type="String" required="true" >
      <cfargument name="user_b" type="String" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['user_a'] = arguments.user_a >
      <cfset options['user_b'] = arguments.user_b >
      <cfset uriBase = buildURL('friendships/exists', arguments.format,options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0destroy --->
    <cffunction name="destroyFriendship" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('friendships/destroy/#arguments.id#', arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0create --->
    <cffunction name="createFriendship" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true">
      <cfargument name="follow" type="boolean" required="false" default="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['follow'] = arguments.follow >
      <cfset uriBase = buildURL('friendships/create/#arguments.id#', arguments.format,options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
	
    <!---  http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-show  --->
    <cffunction name="showFriendship" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" required="true">
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('friendships/show', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>	
    
    <!---  Direct Message Methods --->
    <!--- Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0destroy --->
    <cffunction name="destroyMessage" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('direct_messages/destroy/#arguments.id#',arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0new--->
    <cffunction name="newMessage" access="public" output="false" returntype="string">
      <cfargument name="user" type="String" required="true" >
      <cfargument name="text" type="String" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['user'] = arguments.user >
      <cfset options['text'] = arguments.text >
      <cfset uriBase = buildURL('direct_messages/new', arguments.format,options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0sent --->
    <cffunction name="getSentMessages" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('direct_messages/sent', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages --->
    <cffunction name="getMessages" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('direct_messages', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  User Methods --->
    <!--- Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0followers --->
    <cffunction name="getFollowers" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/followers', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0friends --->
    <cffunction name="getFriends" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/friends', arguments.format,arguments.options) >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show --->
    <cffunction name="showUser" access="public" output="false" returntype="string">
      <cfargument name="screen_name" type="string" required="false" default="#getUsername()#" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = '' 							 >
      <cfset var option = StructNew()							 >
      <cfset option['screen_name'] = arguments.screen_name >
      <cfset uriBase = buildURL('users/show', arguments.format,option) >
      <cfreturn execute(uriBase) >
    </cffunction>
	

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users-search --->    
    <cffunction name="searchUser" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/users/search', arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>
	
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show --->
    <cffunction name="showUserById" access="public" output="false" returntype="string">
      <cfargument name="user_id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = '' 							 >
      <cfset var option = StructNew()							 >
      <cfset option['user_id'] = arguments.user_id >
      <cfset uriBase = buildURL('users/show', arguments.format,option) >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    <!---  Status Methods --->
    <!--- Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0destroy --->
    <cffunction name="destroyStatus" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/destroy/#arguments.id#',arguments.format) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update --->
    <cffunction name="updateStatus" access="public" output="true" returntype="string">
      <cfargument name="status" type="string" required="true" >
      <cfargument name="in_reply_to_status_id" type="string" required="false" default="" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = StructNew() >
      <cfset options['status'] = URLEncodedFormat(arguments.status) >
      <cfif Len(Trim(arguments.in_reply_to_status_id))>
        <cfset options['in_reply_to_status_id'] = arguments.in_reply_to_status_id >
      </cfif>
      <cfset uriBase = buildURL('statuses/update', arguments.format,options) >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>
    

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweet --->
    <cffunction name="retweetStatus" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/retweet/#arguments.id#',arguments.format,structnew(),"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets --->    
    <cffunction name="retweetsStatus" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="options" type="struct" default="#structnew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/retweets/#arguments.id#',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>

    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0show --->
    <cffunction name="getStatus" access="public" output="false" returntype="string">
      <cfargument name="id" type="string" required="true" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/show/#arguments.id#',arguments.format) >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    <!---  Timeline Methods --->
    <!--- Parameters: undocumented --->
    <cffunction name="getReplies" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/replies', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-mentions --->
    <cffunction name="getMentions" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/mentions', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-user_timeline --->
    <cffunction name="getUserTimeline" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/user_timeline', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-friends_timeline --->
    <cffunction name="getFriendsTimeline" access="public" output="false" returntype="string">
      <cfargument name="options" type="Struct" default="#StructNew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/friends_timeline', arguments.format,arguments.options) >
      <cfreturn execute(uriBase, true) >
    </cffunction>
    
    <!---  Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-public_timeline --->
    <cffunction name="getPublicTimeline" access="public" output="false" returntype="string">
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('statuses/public_timeline', arguments.format) >
      <cfreturn execute(uriBase) >
    </cffunction>
    
	
   
    
    <!---  http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-home_timeline --->
    <cffunction name="getHomeTimeline" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" default="#structnew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/home_timeline',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase) >
    </cffunction>
    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets_of_me --->
    <cffunction name="retweetsOfMeStatus" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" default="#structnew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/retweets_of_me',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>    

	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_to_me --->
    <cffunction name="retweetsToMeStatus" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" default="#structnew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/retweeted_to_me',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    

    
	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_by_me --->
    <cffunction name="retweetsByMeStatus" access="public" output="false" returntype="string">
      <cfargument name="options" type="struct" default="#structnew()#" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/statuses/retweeted_by_me',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    


	<!--- List Subscribers Methods --->
	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers-id --->
    <cffunction name="getListSubscriber" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,user,id" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-subscribers --->
    <cffunction name="unSubscribersList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,user" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
	  <cfset arguments.options["_method"]="DELETE" >
      <cfset uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>    
    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-subscribers --->
    <cffunction name="putSubscribers" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,structnew(),"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers --->
    <cffunction name="getListsSubscriber" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    
    
	<!--- List Members Methods --->
	<!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members-id --->
    <cffunction name="getMemberList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    
    

    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-members --->
    <cffunction name="deleteMemberList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="member" type="string" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
      <cfset var options = Structnew() >
	  <cfset options["_method"]="DELETE" >
	  <cfset options["id"]=arguments.member >
      <cfset uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,options,"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-members --->
    <cffunction name="putMembersList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true,true) >
    </cffunction>    
    

    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members --->
    <cffunction name="getMembersList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    

	<!--- List Methods --->    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscriptions --->
    <cffunction name="getSubscriptionsList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists/subscriptions',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    


    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-memberships  --->
    <cffunction name="getMembershipsList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="keys list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists/memberships',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    

    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-statuses --->
    <cffunction name="getStatusList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="since_id,max_id,per_page,page" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#/statuses',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    


    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-id --->
    <cffunction name="deleteList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = "" >
	  <cfset var options = structnew() >
	  <cfset options["_method"]="DELETE" >
      <cfset uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,options,"api.") >
      <cfreturn execute(uriBase, true, true) >
    </cffunction>    
    
    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-id --->
    <cffunction name="getList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,Structnew(),"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    
    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-lists --->
    <cffunction name="getLists" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="list_id,cursor" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true) >
    </cffunction>    
    

    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists-id --->
    <cffunction name="updateList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="list" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="name,mode,description" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true,true) >
    </cffunction>    
    
    
    <!--- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists --->
    <cffunction name="createList" access="public" output="false" returntype="string">
      <cfargument name="user" type="string" >
      <cfargument name="options" type="struct" default="#structnew()#" hint="name,mode,description" required="false" >
      <cfargument name="format" type="string" required="false" default="json" >
      <cfset var uriBase = buildURL('1/#arguments.user#/lists',arguments.format,arguments.options,"api.") >
      <cfreturn execute(uriBase, true,true) >
    </cffunction>	
	
	
    <cffunction name="isTweet" access="public" output="false" returntype="boolean">
      <cfargument name="str" type="string" required="false" default="json" >
      <cfif not Len(Trim(arguments.str)) or arguments.str contains "Connection Timeout" or arguments.str contains "Over capacity">>
        <cfreturn false>
      </cfif>
      <cfreturn true>
    </cffunction>

</cfcomponent>
<!--- 
 @author Pedro Claudio pcsilva@gmail.com
 --->
