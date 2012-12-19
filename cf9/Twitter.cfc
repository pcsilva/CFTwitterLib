/**
* CFTwitterLib - ColdFusion Twitter Lib is implementatio of Twitter API.
* 
* Copyright (c) <2009> Pedro Claudio <pcsilva@gmail.com> 
*  
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses>.
*  
*/
/** 
* Library ColdFusion who allows access Twitter API  
*  
* @author Pedro Claudio
* @since 04/19/2009
*/  
component displayname="Twitter" 
{
	property name="http_status"        setter="false" type="numeric";
	property name="remaining_hits"     setter="false" type="numeric";
	property name="last_api_call"      setter="false" type="string";
	property name="application_source" setter="false" type="string";
	property name="userid"             setter="false" type="string" getter="false";
	property name="screenname"         setter="false" type="string";
	property name="password"           setter="false" type="string";
	property name="My"                 setter="false" type="struct";
	property name="reset_time"         setter="false" type="date";
	property name="nextResetHits"      setter="false" type="date";
	property name="version"            setter="false" type="string";
	property name="currentStatus"      setter="false" type="string";
	property name="http"               setter="false" type="com.adobe.coldfusion.http"   getter="false";
	property name="result"             setter="false" type="com.adobe.coldfusion.result" getter="false";
	

	public Twitter function init(String username, String pass){
		Variables.http_status        = 401;
		Variables.last_api_call      = "";
		Variables.application_source = "cftwitterlib";
		Variables.screenname         = arguments.username;
		Variables.password           = arguments.pass;
		Variables.version            = "9.2";
		Variables.My                 = StructNew();
		Variables.http               = new http();
		Variables.currentStatus             = 'initialized';
		Variables.nextResetHits         = DateAdd('h',1,now());
		setRealRemainingHits();
		setUserid(arguments.username);
		return this;
	}

    public Numeric function lastStatusCode(){
      return getHttp_status();
    }
    
    public String function lastAPICall(){
      return getLast_api_call();
    }

	private void function setRealRemainingHits(){
		Variables.http.setUrl('http://twitter.com/account/rate_limit_status.json');
		Variables.result         = Variables.http.send(); 
		local.Struct             = DeserializeJSON(Variables.result.getPrefix().FileContent);
		Variables.reset_time     = CreateODBCDateTime(local.Struct.reset_time);
		Variables.remaining_hits = local.Struct.remaining_hits;
	} 
	
	public Boolean function isConnectionOpen(){
		local.ret = true;
		Variables.currentStatus = 'active';
		if(Variables.remaining_hits lt 1){
			if(DateDiff('h',Variables.nextResetHits,now()) gt 0){
				Variables.nextResetHits = DateAdd('h',1,now());
				setRealRemainingHits();
				if(Variables.remaining_hits lt 1){
					Variables.currentStatus = 'limit hits exceeded';
					local.ret = false;
				}
			}else{
				Variables.currentStatus = 'limit hits exceeded';
				local.ret = false;
			}
		}else{
			Variables.remaining_hits--;
		}
		return local.ret;
	}

    public Boolean function isTweet(String str){
		local.ret = true;
		if(not Len(Trim(arguments.str)) or arguments.str contains "Connection Timeout" or arguments.str contains "Over capacity"){
			local.ret = false;
		}
		return local.ret;
    }

	
	
    private String function execute(String uriBase,Boolean require_credentials=false,Boolean http_post=false, String path=""){
      local.contentFile = "Connection Timeout";
      try
      {
		if(isConnectionOpen()){
	      	Variables.http.clearParams();
	      	Variables.http.clearAttributes();
	      	Variables.http.setTimeout(5); 
	      	Variables.http.setResolveURL(true); 
	      	Variables.http.setUrl(arguments.uriBase);
			if(arguments.http_post){
				Variables.http.setMethod('post');
				Variables.http.addParam(type="formfield",name="source",value="cftwitterlib");
				if(Len(Trim(arguments.path))){
					Variables.http.addParam(type="file",name="image",file="#arguments.path#");
				}
			}else{
				Variables.http.setMethod('get');
			}
			if(arguments.require_credentials){
				Variables.http.setPassword(Variables.password);
				Variables.http.setUsername(Variables.screenname);
			}
			Variables.result = Variables.http.send();
			local.Struct = Variables.result.getPrefix();
			Variables.http_status = ListFirst(local.Struct.StatusCode, ' ');
			Variables.last_api_call = arguments.uriBase;
			local.contentFile = local.Struct.Filecontent;		
		}
      } 
      catch(coldfusion.runtime.RequestTimedOutException e){
		Variables.http_status = 401;
      }
     return local.contentFile;
    }	

    private function buildURL(String method, String format, Struct options=StructNew(), String prefix=""){
      local.request = "http://#arguments.prefix#twitter.com/#arguments.method#.#arguments.format#";
      local.values = "";
      for(local.key in arguments.options){
      	local.values = ListAppend(local.values,'#lcase(local.key)#=#arguments.options[local.key]#','&');
	  }
      local.request = "#request#?#values#";
      return local.request;
    }

	
	private void function setUserid(String username){
    	local.temp = '';
    	try {
	        local.temp = xmlparse(showUser(arguments.username,'xml'));
	        if(StructKeyExists(local.temp,'user')){
	          userid = local.temp.user.id.xmltext;
	        }
    	}
    	catch(coldfusion.xml.XmlProcessException e){
		}
	}

    public String function getUserid(){
      if(Not Len(Trim(Variables.userid))){
        setUserid(Variables.screenname);
      }
      return Variables.userid;
    }

    /**
    * Search API Methods
    */
    
    
    //Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-weekly
    public String function getTrendsWeekly(Struct options){
      local.uriBase = buildURL('trends/weekly', 'json',arguments.options,'search.');
      return execute(local.uriBase);
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-daily
    public string function getTrendsDaily(Struct options){
      local.uriBase = buildURL('trends/daily', 'json',arguments.options,'search.') ;
      return execute(local.uriBase);
    }
      
    //Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends-current
    public string function getTrendsCurrent(String exclude=true){
      local.excludetag = '' ;
      if(arguments.exclude){
        local.excludetag = '?exclude=hashtags';
      }
      return execute('http://search.twitter.com/trends/current.json#local.excludetag#');
    }
     
    //Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-trends
    public String function getTrends(){
      return execute('http://search.twitter.com/trends.json');
    }

    //Parameters: http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-search
    public string function search(Struct options, String format='atom'){
      local.uriBase = buildURL('search', arguments.format,arguments.options,'search.');
      return execute(local.uriBase);
    }


    /**
    * REST API Methods
    */


    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-help%C2%A0test
    public string function test(String id, String format="json"){
      local.uriBase = buildURL('help/test/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true) ;
    }




	// Trends Location Methods
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-trends-location
    public string function trendsLocation(numeric woeid, String format="json"){
	  	local.uriBase = buildURL('1/trends/#arguments.woeid#', arguments.format,StructNew(),"api.") ;
      	return execute(local.uriBase,true);
    }

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-trends-available
    public string function trendsAvailable(Struct options, String format="json"){
	  local.uriBase = buildURL('1/trends/available', arguments.format,arguments.options,"api.");
      return execute(local.uriBase);
    }
    

	// Saved Searches Methods    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-destroy
    public string function searchesDestroy(String id, String format="json"){
      local.uriBase = buildURL('saved_searches/destroy/#arguments.id#', arguments.format);
      return  execute(local.uriBase, true, true);
    }

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-create    
    public string function searchesCreate(String query, String format="json"){
		local.options = StructNew();
        local.options['query'] = arguments.query;
		local.uriBase = buildURL('saved_searches/create', arguments.format,local.options);
        return  execute(local.uriBase, true, true);
    }

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches-show
    public string function searchesShow(String id, String format="json"){
      local.uriBase = buildURL('saved_searches/show/#arguments.id#', arguments.format);
      return  execute(local.uriBase, true, true);
    }
    
    
	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-saved_searches
    public string function searchesSaved(String format="json"){
      local.uriBase = buildURL('saved_searches', arguments.format);
      return  execute(local.uriBase, true);
    }


    // Spam Reporting Methods
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-report_spam
    public string function reportingSpam(Struct options, String format="json"){
      local.uriBase = buildURL('report_spam', arguments.format, arguments.options);
      return  execute(local.uriBase, true, true);
    }



    //Block Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0destroy
    public string function destroyBlock(String id,String format="json"){
      local.uriBase = buildURL('blocks/destroy/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true);
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-blocks%C2%A0create
    public string function createBlock(String id,String format="json"){
      local.uriBase = buildURL('blocks/create/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
  
    //  Notification Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0leave
    public string function leave(String id, String format="json"){
      local.uriBase = buildURL('notifications/leave/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-notifications%C2%A0follow
    public string function follow(String id, String format="json"){
      local.uriBase = buildURL('notifications/follow/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }  
  

    //  Favorite Methods
    
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0destroy
    public string function destroyFavorite(String id, String format="json"){
      local.uriBase = buildURL('favorites/destroy/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites%C2%A0create
    public string function createFavorite(String id, String format="json"){
      local.uriBase = buildURL('favorites/create/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-favorites
    public string function getFavorites(String id="",Struct options=StructNew(),String format="json"){
      if(Len(Trim(arguments.id))){
        local.uriBase = buildURL('favorites/#arguments.id#', arguments.format) ;
      }else{
        local.uriBase = buildURL('favorites', arguments.format) ;
      }
      return execute(local.uriBase, true) ;
    }
    
    
    //  Account Methods
	
    // Parameters: (image) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_image
    public string function updateProfileImageBackground(String path, String title, String format="json"){
      local.options = StructNew() ;
      local.options['title'] = arguments.title ;
      local.uriBase = buildURL('account/update_profile_background_image', arguments.format,options) ;
      return execute(local.uriBase, true, true,arguments.path) ;
    }
    
    //Parameters: (image) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_image
    public string function updateProfileImage(String path, String format="json"){
      local.uriBase = buildURL('account/update_profile_image', arguments.format) ;
      return execute(local.uriBase, true, true,arguments.path) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile
    public string function updateProfile(Struct options,String format="json"){
      local.uriBase = buildURL('account/update_profile', arguments.format,arguments.options) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_profile_colors
    public string function updateProfileColors(Struct options,String format="json"){
      local.uriBase = buildURL('account/update_profile_colors', arguments.format,arguments.options) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0update_delivery_device
    public string function updateDeliveryDevice(String device, String format="json"){
      local.options = StructNew() ;
      local.options['device'] = arguments.device ;
      local.uriBase = buildURL('account/update_delivery_advice', arguments.format,options) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0end_session
    public string function endSession(String format="json"){
      local.uriBase = buildURL('account/end_session', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0rate_limit_status
    public string function rateLimitStatus(Boolean allusers=true,String format="json"){
      local.uriBase = buildURL('account/rate_limit_status', arguments.format) ;
      return execute(local.uriBase, arguments.allusers) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0verify_credentials
    public string function verifyCredentials(String format="json"){
      local.uriBase = buildURL('account/verify_credentials', arguments.format) ;
      return execute(local.uriBase, true) ;
    }

    
	
    //  Social Graph Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-followers%C2%A0ids
    public string function getFollowerIDs(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('followers/ids', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friends%C2%A0ids
    public string function getFriendIDs(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('friends/ids', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
   
   
    
	
    //  Friendship Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-exists
    public string function friendshipExists(String user_a, String user_b, String format="json"){
      local.options = StructNew() ;
      local.options['user_a'] = arguments.user_a ;
      local.options['user_b'] = arguments.user_b ;
      local.uriBase = buildURL('friendships/exists', arguments.format, local.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0destroy
    public string function destroyFriendship(String id, String format="json"){
      local.uriBase = buildURL('friendships/destroy/#arguments.id#', arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships%C2%A0create
    public string function createFriendship(String id, Boolean follow=true, String format="json"){
      local.options = StructNew() ;
      local.options['follow'] = arguments.follow ;
      local.uriBase = buildURL('friendships/create/#arguments.id#', arguments.format, local.options) ;
      return execute(local.uriBase, true, true) ;
    }
    
	
	
    //  http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-friendships-show 
    public string function showFriendship(Struct options, String format="json"){
      local.uriBase = buildURL('friendships/show', arguments.format,arguments.options);
      return  execute(local.uriBase, true, true);
    }
		
    //  Direct Message Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0destroy
    public string function destroyMessage(String id, String format="json"){
      local.uriBase = buildURL('direct_messages/destroy/#arguments.id#',arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0new
    public string function newMessage(String user, String text, String format="json"){
      local.options = StructNew() ;
      local.options['user'] = arguments.user ;
      local.options['text'] = arguments.text ;
      local.uriBase = buildURL('direct_messages/new', arguments.format, local.options) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages%C2%A0sent
    public string function getSentMessages(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('direct_messages/sent', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-direct_messages
    public string function getMessages(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('direct_messages', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }



    // User Methods
	
    // Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0followers
    public string function getFollowers(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/followers', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0friends
    public string function getFriends(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/friends', arguments.format,arguments.options) ;
      return execute(local.uriBase);
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show
    public string function showUser(String screen_name=getUsername(),String format="json"){ 							 ;
      local.option = StructNew();
      local.option['screen_name'] = arguments.screen_name ;
      local.uriBase = buildURL('users/show', arguments.format,local.option) ;
      return execute(local.uriBase);
    }


	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users-search    
    public string function searchUser(Struct options, String format="json"){
      local.uriBase = buildURL('1/users/search', arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }

    
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show
    public string function showUserById(String user_id,String format="json"){
      local.option = StructNew();
      local.option['user_id'] = arguments.user_id ;
      local.uriBase = buildURL('users/show', arguments.format,local.option) ;
      return execute(local.uriBase);
    }
    
    //  Status Methods
    
    // Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0destroy
    public string function destroyStatus(String id, String format="json"){
      local.uriBase = buildURL('statuses/destroy/#arguments.id#',arguments.format) ;
      return execute(local.uriBase, true, true) ;
    }
    
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update
    public string function updateStatus(String status, String in_reply_to_status_id="", String format="json"){
      local.options = StructNew() ;
      local.options['status'] = URLEncodedFormat(arguments.status) ;
      if(Len(Trim(arguments.in_reply_to_status_id))){
        local.options['in_reply_to_status_id'] = arguments.in_reply_to_status_id ;
      }
      local.uriBase = buildURL('statuses/update', arguments.format, local.options) ;
      return execute(local.uriBase, true, true) ;
    }
    
    

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweet
    public string function retweetStatus(String id, String format="json"){
      local.uriBase = buildURL('1/statuses/retweet/#arguments.id#',arguments.format,structnew(),"api.");
      return  execute(local.uriBase, true, true);
    }

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets    
    public string function retweetsStatus(String id,Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('1/statuses/retweets/#arguments.id#',arguments.format,arguments.options,"api.");
      return  execute(uri, true, true);
    }	
	
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0show
    public string function getStatus(String id, String format="json"){
      local.uriBase = buildURL('statuses/show/#arguments.id#',arguments.format) ;
      return execute(local.uriBase);
    }   
   
    //  Timeline Methods
    
    // Parameters: undocumented
    public string function getReplies(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/replies', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-mentions
    public string function getMentions(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/mentions', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-user_timeline
    public string function getUserTimeline(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/user_timeline', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-friends_timeline
    public string function getFriendsTimeline(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('statuses/friends_timeline', arguments.format,arguments.options) ;
      return execute(local.uriBase, true) ;
    }
    
    //Parameters: (no parameters) http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-public_timeline
    public string function getPublicTimeline(String format="json"){
      local.uriBase = buildURL('statuses/public_timeline', arguments.format) ;
      return execute(local.uriBase);
    }   
   
    //  http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-home_timeline
    public string function getHomeTimeline(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('1/statuses/home_timeline',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase);
    }
    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweets_of_me
    public string function retweetsOfMeStatus(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('1/statuses/retweets_of_me',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true, true);
    }    

	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_to_me
    public string function retweetsToMeStatus(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('1/statuses/retweeted_to_me',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    

    
	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-retweeted_by_me
    public string function retweetsByMeStatus(Struct options=StructNew(), String format="json"){
      local.uriBase = buildURL('1/statuses/retweeted_by_me',arguments.format,arguments.options,"api.");
      return  execute(uri, true);
    }    


	// List Subscribers Methods
	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers-id
    public string function getListSubscriber(String user, String list, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-subscribers
    public string function unSubscribersList(String user, String list, Struct options=structnew(), String format="json"){
	  arguments.options["_method"]="DELETE";
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true, true);
    }    
    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-subscribers
    public string function putSubscribers(String user, String list, String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,structnew(),"api.");
      return  execute(local.uriBase, true, true);
    }    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscribers
    public string function getListsSubscriber(String user, String list, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/subscribers',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    
    
	// List Members Methods
	// http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members-id
    public string function getMemberList(String user, String list, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.") ;
      return  execute(local.uriBase, true);
    }    
    

    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-members
    public string function deleteMemberList(String user, String list, String member, String format="json"){
      local.options = Structnew();
	  local.options["_method"]="DELETE";
	  local.options["id"]=arguments.member;
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,local.options,"api.");
      return  execute(local.uriBase, true, true);
    }    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-list-members
    public string function putMembersList(String user, String list,Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true,true);
    }    
    

    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-members
    public string function getMembersList(String user, String list,Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/#arguments.list#/members',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    

	// List Methods    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-subscriptions
    public string function getSubscriptionsList(String user, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists/subscriptions',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    


    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-memberships 
    public string function getMembershipsList(String user, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists/memberships',arguments.format,arguments.options,"api.") ;
      return  execute(local.uriBase, true);
    }    

    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-statuses
    public string function getStatusList(String user, String list, Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#/statuses',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    


    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-DELETE-list-id
    public string function deleteList(String user, String list, String format="json"){
	  local.options = structnew();
	  local.options["_method"]="DELETE";
      local.uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,local.options,"api.");
      return  execute(local.uriBase, true, true);
    }    
    
    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-list-id
    public string function getList(String user, String list, String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,Structnew(),"api.");
      return  execute(local.uriBase, true);
    }    
    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-GET-lists
    public string function getLists(String user,Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true);
    }    
    

    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists-id
    public string function updateList(String user, String list,Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists/#arguments.list#',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true,true);
    }    
    
    
    // http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-POST-lists
    public string function createList(String user,Struct options=structnew(), String format="json"){
      local.uriBase = buildURL('1/#arguments.user#/lists',arguments.format,arguments.options,"api.");
      return  execute(local.uriBase, true,true);
    }	
   
   
   
}