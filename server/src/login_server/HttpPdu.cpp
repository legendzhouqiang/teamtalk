/*
 * HttpPdu.cpp
 *
 *  Created on: 2013-10-1
 *      Author: ziteng@mogujie.com
 */

#include "util.h"
#include "HttpPdu.h"
#include "jsonxx.h"

#define HTTP_HEADER "HTTP/1.1 200 OK\r\n"\
		"Cache-Control:no-cache\r\n"\
		"Connection:close\r\n"\
		"Content-Length:%d\r\n"\
		"Content-Type:application/javascript\r\n\r\n%s(%s)"

#define HTTP_QUEYR_HEADER "HTTP/1.1 200 OK\r\n"\
		"Cache-Control:no-cache\r\n"\
		"Connection:close\r\n"\
		"Content-Length:%d\r\n"\
		"Content-Type:text/html;charset=utf-8\r\n\r\n%s"

#define MAX_BUF_SIZE 819200

#define OK_CODE		1001
#define OK_MSG		"OK"
#define ERROR_CODE_OFFSET	4000
const char* g_error_msg[] = {
	"general error",			// 4000
	"parse parameter failed", 	// 4001
	"parameter miss",			// 4002
	"uuid not match",			// 4003
	"token not valid",			// 4004
	"no business server",		// 4005
	"parse json failed",		// 4006
	"no http user",				// 4007
	"no such method",			// 4008
};

// for single thread
static char g_response_buf[MAX_BUF_SIZE];


bool CPostDataParser::Parse(const char* content)
{
	char* key_start = (char*)content;
	bool complete = false;

	while (!complete) {
		char* key_end = strchr(key_start, '=');
		if (!key_end) {
			return false;
		}

		std::string key(key_start, key_end - key_start);

		char* value_start = key_end + 1;
		char* value_end = strchr(value_start, '&');
		if (!value_end) {
			complete = true;
			value_end = value_start + strlen(value_start);
		}

		std::string value(value_start, value_end - value_start);
		//printf("post data: %s:%s\n", key.c_str(), value.c_str());
		m_post_map.insert(make_pair(key, value));

		key_start = value_end + 1;
	}
	return true;
}

char* CPostDataParser::GetValue(const char* key)
{
	std::map<std::string, std::string>::iterator it = m_post_map.find(key);

	if (it != m_post_map.end()) {
		return (char*)it->second.c_str();
	}

	return NULL;
}

CAttachData::CAttachData(uint32_t http_handle, uint32_t uuid, const char* callback_str)
{
	CByteStream os(&m_buf, 0);

	os << http_handle;
	os << uuid;
	os.WriteString(callback_str);
}

CAttachData::CAttachData(uchar_t* attach_data, uint32_t attach_len)
{
	CByteStream is(attach_data, attach_len);

	char* callback = NULL;
	uint32_t callback_len = 0;
	is >> m_http_handle;
	is >> m_uuid;
	callback = is.ReadString(callback_len);
	m_callback.append(callback, callback_len);
}

char* GetErrorMsg(uint32_t error_code)
{
	uint32_t index = error_code - ERROR_CODE_OFFSET;
	if (index > sizeof(g_error_msg)) {
		index = 0;
	}

	return (char*)g_error_msg[index];
}

char* PackErrorResponse(const char* callback, uint32_t code)
{
	jsonxx::Object json_obj, status_obj, result_obj;

	json_obj << "code" << code;
	json_obj << "msg" << jsonxx::String(GetErrorMsg(code));
	json_obj << "data" << "";

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());

	return g_response_buf;
}

char* PackOKResponse(const char* callback)
{
	jsonxx::Object json_obj;

	json_obj << "code" << 1001;
	json_obj << "msg" << "OK";
	json_obj << "data" << "";

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());

	return g_response_buf;
}

char* PackLoginResponse(const char* callback, uint32_t result, uint32_t uuid,
		const char* name, const char* avatar_url, uint32_t user_type)
{
	jsonxx::Object json_obj, status_obj, result_obj;

	status_obj << "code" << OK_CODE;
	status_obj << "msg" << jsonxx::String(OK_MSG);

	result_obj << "result" << result;
	if (result == 0) {
		result_obj << "uuid" << uuid;
		result_obj << "name" << jsonxx::String(name);
		result_obj << "avatar" << jsonxx::String(avatar_url);
		result_obj << "userType" << user_type;
	}

	json_obj << "status" << status_obj;
	json_obj << "result" << result_obj;

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());

	return g_response_buf;
}

char* PackFriendList(const char* callback, const char* type, uint32_t friend_cnt, user_info_t* friend_list)
{
	jsonxx::Object json_obj, friend_obj;
	jsonxx::Array data_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "type" << jsonxx::String(type);

	for (uint32_t i = 0; i < friend_cnt; i++) {
		user_info_t* user = friend_list + i;
		char* id_url = idtourl(user->user_id);
		std::string uname;
		if (user->nick_name_len > 0) {
			uname.append(user->nick_name, user->nick_name_len);
		} else {
			uname.append(user->name, user->name_len);
		}
		std::string avatar(user->avatar_url, user->avatar_len);

		friend_obj << "uid" << jsonxx::String(id_url);
		friend_obj << "uname" << uname;
		friend_obj << "avatar" << avatar;
		friend_obj << "userType" << user->user_type;
		friend_obj << "status" << (uint32_t)USER_STATUS_OFFLINE;

		data_obj << friend_obj;
		friend_obj.reset();
	}

	json_obj << "data" << data_obj;

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
	return g_response_buf;
}

char* PackFriendList(const char* callback, const char* type, uint32_t friend_cnt, user_info_ext_t* friend_list)
{
    jsonxx::Object json_obj, friend_obj;
    jsonxx::Array data_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String(type);
    
    for (uint32_t i = 0; i < friend_cnt; i++) {
        user_info_ext_t* user = friend_list + i;
        char* id_url = idtourl(user->user_info.user_id);
        std::string uname;
        if (user->user_info.nick_name_len > 0) {
            uname.append(user->user_info.nick_name, user->user_info.nick_name_len);
        } else {
            uname.append(user->user_info.name, user->user_info.name_len);
        }
        std::string avatar(user->user_info.avatar_url, user->user_info.avatar_len);
        
        friend_obj << "uid" << jsonxx::String(id_url);
        friend_obj << "uname" << uname;
        friend_obj << "avatar" << avatar;
        friend_obj << "userType" << user->user_info.user_type;
        friend_obj << "status" << (uint32_t)USER_STATUS_OFFLINE;
        string shop_name(user->shop_info.shop_name, user->shop_info.shop_name_len);
        friend_obj << "bname" << shop_name;
        
        data_obj << friend_obj;
        friend_obj.reset();
    }
    
    json_obj << "data" << data_obj;
    
    std::string json_str = json_obj.json();
    
    int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
    return g_response_buf;
}

char* PackFriendList(uint32_t friend_cnt, user_info_t* friend_list)
{
	jsonxx::Object json_obj, friend_obj;
	jsonxx::Array data_obj;


	for (uint32_t i = 0; i < friend_cnt; i++) {
		user_info_t* user = friend_list + i;

		std::string uname;
		if (user->nick_name_len > 0) {
			uname.append(user->nick_name, user->nick_name_len);
		} else {
			uname.append(user->name, user->name_len);
		}
		std::string avatar(user->avatar_url, user->avatar_len);

		friend_obj << "uid" << user->user_id;
		friend_obj << "uname" << uname;
		friend_obj << "avatar" << avatar;
		friend_obj << "userType" << user->user_type;

		data_obj << friend_obj;
		friend_obj.reset();
	}

	json_obj << "data" << data_obj;

	std::string json_str = json_obj.json();

	int content_length = (int)json_str.size();
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_length, json_str.c_str());
	return g_response_buf;
}

char* PackFriendList(uint32_t friend_cnt, user_info_ext_t* friend_list)
{
    jsonxx::Object json_obj, friend_obj;
    jsonxx::Array data_obj;
    
    
    for (uint32_t i = 0; i < friend_cnt; i++) {
        user_info_ext_t* user = friend_list + i;
        
        std::string uname;
        if (user->user_info.nick_name_len > 0) {
            uname.append(user->user_info.nick_name, user->user_info.nick_name_len);
        } else {
            uname.append(user->user_info.name, user->user_info.name_len);
        }
        std::string avatar(user->user_info.avatar_url, user->user_info.avatar_len);
        
        friend_obj << "uid" << user->user_info.user_id;
        friend_obj << "uname" << uname;
        friend_obj << "avatar" << avatar;
        friend_obj << "userType" << user->user_info.user_type;
        string shop_name(user->shop_info.shop_name, user->shop_info.shop_name_len);
        friend_obj << "bname" << shop_name;
        
        data_obj << friend_obj;
        friend_obj.reset();
    }
    
    json_obj << "data" << data_obj;
    
    std::string json_str = json_obj.json();
    
    int content_length = (int)json_str.size();
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_length, json_str.c_str());
    return g_response_buf;
}

char* PackUnreadMsgCntResponse(const char* callback, uint32_t unread_cnt, UserUnreadMsgCnt_t* unread_list)
{
	jsonxx::Object json_obj, unread_obj;
	jsonxx::Array data_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "type" << jsonxx::String("getMyUnreadMsgCount");

	for (uint32_t i = 0; i < unread_cnt; i++) {
		char* id_url = idtourl(unread_list[i].from_user_id);

		unread_obj << "userId" << jsonxx::String(id_url);
		unread_obj << "count" << unread_list[i].unread_msg_cnt;

		data_obj << unread_obj;
		unread_obj.reset();
	}

	json_obj << "data" << data_obj;

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
	return g_response_buf;
}

char* PackUnreadMsgCntResponse(uint32_t unread_cnt, UserUnreadMsgCnt_t* unread_list)
{
	jsonxx::Object json_obj, unread_obj;
	jsonxx::Array data_obj;

	for (uint32_t i = 0; i < unread_cnt; i++) {
		unread_obj << "fromUserId" << unread_list[i].from_user_id;
		unread_obj << "count" << unread_list[i].unread_msg_cnt;

		data_obj << unread_obj;
		unread_obj.reset();
	}

	json_obj << "data" << data_obj;

	std::string json_str = json_obj.json();

	int content_length =  (int)json_str.size();
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_length, json_str.c_str());
	return g_response_buf;
}

char* PackMsgListResponse(const char* callback, const char* action_type, uint32_t display_id, uint32_t msg_cnt, server_msg_t* msg_list)
{
	jsonxx::Object json_obj, data_obj;
	jsonxx::Array msg_list_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "type" << jsonxx::String(action_type);

	std::string display_id_url = idtourl(display_id);
	for (uint32_t i = 0; i < msg_cnt; i++) {
		jsonxx::Object msg_obj, user_obj;
		server_msg_t* msg = &msg_list[i];
		std::string from_id_url = idtourl(msg->from_user_id);

		msg_obj << "displayUserId" << display_id_url;
		msg_obj << "createTime" << msg->create_time;
        
        uint8_t msgType = msg->msg_type;
        if (msg->msg_type == MSG_TYPE_AUDIO) {
			msg_obj << "msgContent" << jsonxx::String(AUDIO_CONTENT_TEXT);
            msgType = MSG_TYPE_TEXT;
		} else {
            string strContent((char*)msg->msg_data, msg->msg_len);
            XSSFilter(strContent);
			msg_obj << "msgContent" << jsonxx::String(strContent);
		}
        
		msg_obj << "msgType" << msgType;

		user_obj << "userId" << from_id_url;
		if (msg->from_nick_name_len > 0) {
			user_obj << "userName" << jsonxx::String(msg->from_nick_name, msg->from_nick_name_len);
		} else {
			user_obj << "userName" << jsonxx::String(msg->from_name, msg->from_name_len);
		}
		user_obj << "userAvatar" << jsonxx::String(msg->from_avatar_url, msg->from_avatar_len);
		msg_obj << "fromUser" << user_obj;

		msg_list_obj << msg_obj;
	}

	if (strcmp(action_type, "getAllHistoryMsg") == 0) {
		json_obj << "data" << msg_list_obj;
	} else {
		data_obj << "displayUserId" << display_id_url;
		data_obj << "msgList" << msg_list_obj;
		json_obj << "data" << data_obj;
	}

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
	return g_response_buf;
}

char* PackMsgListResponse(uint32_t msg_cnt, server_msg_t* msg_list)
{
	jsonxx::Object json_obj, data_obj;
	jsonxx::Array msg_list_obj;

	if (msg_cnt != 0)
	{
		server_msg_t* msg = &msg_list[0];
		json_obj << "hasMsg" << 1;
		json_obj << "createTime" << msg->create_time;

        uint8_t msgType = msg->msg_type;

        if (msg->msg_type == MSG_TYPE_AUDIO) {
			json_obj << "msgContent" << jsonxx::String(AUDIO_CONTENT_TEXT);
            msgType = MSG_TYPE_TEXT;
		} else {
            string strContent((char*)msg->msg_data, msg->msg_len);
            XSSFilter(strContent);
			json_obj << "msgContent" << jsonxx::String(strContent);
		}
    
        json_obj << "msgType" << msgType;

		json_obj << "fromUserId" << msg->from_user_id;
	} else {
		json_obj << "hasMsg" << 0;
	}

	std::string json_str = json_obj.json();

	int content_length =  (int)json_str.size();
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_length, json_str.c_str());
	return g_response_buf;
}

char* PackAddNewUserResponse(const char* callback, uint32_t online_status, uint32_t user_cnt, user_info_t* user_list)
{
	log("PackAddNewUserResponse, user_cnt=%u\n", user_cnt);	// for debug
	jsonxx::Object json_obj, friend_obj;
	jsonxx::Array data_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "type" << jsonxx::String("addNewUser");

	for (uint32_t i = 0; i < user_cnt; i++) {
		user_info_t* user = user_list + i;
		char* id_url = idtourl(user->user_id);
		std::string uname;
		if (user->nick_name_len > 0) {
			uname.append(user->nick_name, user->nick_name_len);
		} else {
			uname.append(user->name, user->name_len);
		}
		std::string avatar(user->avatar_url, user->avatar_len);

		friend_obj << "uid" << jsonxx::String(id_url);
		friend_obj << "uname" << uname;
		friend_obj << "avatar" << avatar;
		friend_obj << "userType" << user->user_type;
		friend_obj << "status" << online_status;

		data_obj << friend_obj;
		friend_obj.reset();
	}

	json_obj << "data" << data_obj;

	std::string json_str = json_obj.json();

	int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
	return g_response_buf;
}

char* PackAddNewUserWithShopInfoResponse(const char* callback, uint32_t online_status, uint32_t user_cnt, user_info_ext_t* user_list)
{
    log("PackAddNewUserWithShopInfoResponse, user_cnt=%u\n", user_cnt);	// for debug
    jsonxx::Object json_obj, friend_obj;
    jsonxx::Array data_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String("addNewUser");
    
    for (uint32_t i = 0; i < user_cnt; i++) {
        user_info_ext_t* user = user_list + i;
        char* id_url = idtourl(user->user_info.user_id);
        std::string uname;
        if (user->user_info.nick_name_len > 0) {
            uname.append(user->user_info.nick_name, user->user_info.nick_name_len);
        } else {
            uname.append(user->user_info.name, user->user_info.name_len);
        }
        std::string avatar(user->user_info.avatar_url, user->user_info.avatar_len);
        std::string bname(user->shop_info.shop_name, user->shop_info.shop_name_len);
        friend_obj << "uid" << jsonxx::String(id_url);
        friend_obj << "uname" << uname;
        friend_obj << "avatar" << avatar;
        friend_obj << "userType" << user->user_info.user_type;
        friend_obj << "status" << online_status;
        friend_obj << "bname" << bname;
        
        data_obj << friend_obj;
        friend_obj.reset();
    }
    
    json_obj << "data" << data_obj;
    
    std::string json_str = json_obj.json();
    
    int content_length = (int)strlen(callback) + (int)json_str.size() + 2;
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, json_str.c_str());
    return g_response_buf;
}

char* PackMsgData(const char* from_id, const char* to_id, const char* msg_content, uint8_t msgType)
{
	jsonxx::Object json_obj, data_obj;

	data_obj << "toUid" << jsonxx::String(to_id);
	data_obj << "fromUid" << jsonxx::String(from_id);
    
    string strContent(msg_content);
    XSSFilter(strContent);
	data_obj << "content" << jsonxx::String(strContent);
    data_obj << "msgType" << msgType;
    
	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "";
	json_obj << "type" << jsonxx::String("receiveMessage");
	json_obj << "data" << data_obj;

	snprintf(g_response_buf, MAX_BUF_SIZE, "%s", json_obj.json().c_str());
	return g_response_buf;
}

char* PackP2PMsg(const char* msg_content)
{
	/*jsonxx::Object json_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "";
	json_obj << "type" << jsonxx::String("receiveData");
	json_obj << "data" << jsonxx::String(msg_content);*/
    string strContent(msg_content);
    XSSFilter(strContent);
    
	snprintf(g_response_buf, MAX_BUF_SIZE, "{\"code\": 1001, \"msg\": \"\", \"type\": \"receiveData\", \"data\": %s}",
			strContent.c_str());
	//log("g_response_buf: %s\n", g_response_buf);
	return g_response_buf;
}

char* PackStatusChange(uint32_t user_cnt, user_stat_t* user_stat_list)
{
	jsonxx::Object json_obj, stat_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "";
	json_obj << "type" << jsonxx::String("statusChange");

	// 如果只有一个用户状态改变，就不要返回json数组
	if (user_cnt == 1) {
		std::string id_url = idtourl(user_stat_list[0].user_id);
		stat_obj << "uid" << id_url;
		stat_obj << "status" << user_stat_list[0].status;

		json_obj << "data" << stat_obj;
	} else {
		jsonxx::Array data_obj;

		for (uint32_t i = 0; i < user_cnt; i++) {
			std::string id_url = idtourl(user_stat_list[i].user_id);
			stat_obj << "uid" << id_url;
			stat_obj << "status" << user_stat_list[i].status;

			data_obj << stat_obj;
			stat_obj.reset();
		}

		json_obj << "data" << data_obj;
	}

	snprintf(g_response_buf, MAX_BUF_SIZE, "%s", json_obj.json().c_str());
	return g_response_buf;
}

char* PackErrorCode(uint32_t error_code)
{
	jsonxx::Object json_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "";
	json_obj << "type" << jsonxx::String("errorCode");
	json_obj << "data" << error_code;

	snprintf(g_response_buf, MAX_BUF_SIZE, "%s", json_obj.json().c_str());
	return g_response_buf;
}

char* PackAddNewUser(const char* action_type, uint32_t shop_id, uint32_t service_type, uint32_t status, user_info_t* user)
{
	jsonxx::Object json_obj, friend_obj;
	jsonxx::Array data_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "";
	json_obj << "type" << jsonxx::String(action_type);

	string id_url = idtourl(user->user_id);
	std::string uname;
	if (user->nick_name_len > 0) {
		uname.append(user->nick_name, user->nick_name_len);
	} else {
		uname.append(user->name, user->name_len);
	}
	std::string avatar(user->avatar_url, user->avatar_len);

	friend_obj << "uid" << id_url;
	friend_obj << "uname" << uname;
	friend_obj << "avatar" << avatar;
	friend_obj << "userType" << user->user_type;
	friend_obj << "status" << status;

	if (strcmp(action_type, "addNewBusinessUser") == 0) {
		string shop_id_url = idtourl(shop_id);
		friend_obj << "bid" << shop_id_url;
		friend_obj << "serviceType" << service_type;
	} else {
		friend_obj << "welcome" << jsonxx::Boolean(true);
	}

	data_obj << friend_obj;
	json_obj << "data" << data_obj;
	snprintf(g_response_buf, MAX_BUF_SIZE, "%s", json_obj.json().c_str());
	return g_response_buf;
}

char* PackAddNewUserWithShopName(const char* action_type, uint32_t shop_id, uint32_t service_type, uint32_t status, user_info_t* user, const char* shop_name)
{
    jsonxx::Object json_obj, friend_obj;
    jsonxx::Array data_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "msg" << "";
    json_obj << "type" << jsonxx::String(action_type);
    
    string id_url = idtourl(user->user_id);
    std::string uname;
    if (user->nick_name_len > 0) {
        uname.append(user->nick_name, user->nick_name_len);
    } else {
        uname.append(user->name, user->name_len);
    }
    std::string avatar(user->avatar_url, user->avatar_len);
    std::string bname(shop_name);
    
    friend_obj << "uid" << id_url;
    friend_obj << "uname" << uname;
    friend_obj << "avatar" << avatar;
    friend_obj << "userType" << user->user_type;
    friend_obj << "status" << status;
    friend_obj << "bname" << bname;

    if (strcmp(action_type, "addNewBusinessUser") == 0) {
        string shop_id_url = idtourl(shop_id);
        friend_obj << "bid" << shop_id_url;
        friend_obj << "serviceType" << service_type;
    } else {
        friend_obj << "welcome" << jsonxx::Boolean(true);
    }
    
    data_obj << friend_obj;
    json_obj << "data" << data_obj;
    snprintf(g_response_buf, MAX_BUF_SIZE, "%s", json_obj.json().c_str());
    return g_response_buf;
}

char* PackPollData(const char* callback, const char* payload_data)
{
	//log("callback=%s, payload_data=%s\n", callback, payload_data);
	int content_length = (int)strlen(callback) + (int)strlen(payload_data) + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_length, callback, payload_data);
	//log("%s\n", g_response_buf);
	return g_response_buf;
}


char* PackOnlineStatus(uint32_t user_cnt, user_stat_t* user_stat_list)
{
	jsonxx::Object json_obj, stat_obj;
	jsonxx::Array stat_list_obj;

	for (uint32_t i = 0; i < user_cnt; i++) {
		stat_obj << "userId" << user_stat_list[i].user_id;
		stat_obj << "status" << user_stat_list[i].status;
		stat_list_obj << stat_obj;
		stat_obj.reset();
	}

	json_obj << "data" << stat_list_obj;
	json_obj << "code" << OK_CODE;

	std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();

	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	//log("PackOnlineStatus: %s\n", g_response_buf);
	return g_response_buf;
}

char* PackSendMsgOk()
{
	jsonxx::Object json_obj;

	json_obj << "code" << OK_CODE;
	json_obj << "msg" << "OK";

	std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();

	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

char* PackTotalQuery(uint32_t total_query)
{
	jsonxx::Object json_obj;
	uint32_t timestamp = time(NULL);

	json_obj << "code" << OK_CODE;
	json_obj << "totalQuery" << total_query;
	json_obj << "timestamp" << timestamp;

	std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();

	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

char* PackOnlineUserCnt(uint32_t online_user_cnt)
{
	jsonxx::Object json_obj;
	uint32_t timestamp = (uint32_t)time(NULL);

	json_obj << "code" << OK_CODE;
	json_obj << "totalOnlineUser" << online_user_cnt;
	json_obj << "timestamp" << timestamp;

	std::string json_str = json_obj.json();
	uint32_t content_len = (uint32_t)json_str.size();

	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

char* PackCreateGroupResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const string& groupName, const string& groupDesc, uint32_t userCnt, uint32_t* userIdList, uint32_t memberLimited, uint32_t source_type)
{
    jsonxx::Object json_obj, group_obj;
    jsonxx::Array  list_obj;
    
	json_obj << "code" << OK_CODE;
	json_obj << "type" << jsonxx::String("createGroup");
    json_obj << "result" << result;
	string id_url = idtourl(reqUserId);
    if(!result)
    {
        group_obj << "groupId" << groupid;
        group_obj << "groupName" << jsonxx::String(groupName);
        group_obj << "groupDesc" << jsonxx::String(groupDesc);
        for (uint32_t i = 0; i < userCnt; ++i) {
            list_obj << userIdList[i];
        }
        group_obj << "usersIdList" << list_obj;
        group_obj << "memberLimited" << memberLimited;
        group_obj << "sourceType" << source_type;
        json_obj << "data" << group_obj;
    }
    
    std::string json_str = json_obj.json();
	uint32_t content_len = (uint32_t)json_str.size();
    
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;

}

char* PackGroupInfoResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const string&  groupName, const string& groupDesc, uint32_t groupType, const list<member_info_t>& groupMemberList)
{
    jsonxx::Object json_obj, group_obj;
    jsonxx::Array  list_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String("getGroupInfo");
    json_obj << "result" << result;
    group_obj << "groupId" << groupid;

    string id_url = idtourl(reqUserId);
    if(!result)
    {
        group_obj << "groupName" << groupName;
        group_obj << "groupDesc" << groupDesc;
        uint32_t memberCount = (uint32_t)groupMemberList.size();
        group_obj << "memberCount" << memberCount;
        json_obj << "data" << group_obj;
    }
    
    std::string json_str = json_obj.json();
    uint32_t content_len = (uint32_t)json_str.size();
    
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
    return g_response_buf;
}

char* PackGroupMemberResponse(uint32_t reqUserId, uint32_t result, uint32_t groupid, const list<member_info_ext_t>& groupMemberList)
{
    jsonxx::Object json_obj, group_obj;
    jsonxx::Array  list_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String("getGroupInfo");
    json_obj << "result" << result;
    group_obj << "groupId" << groupid;
    
    //string id_url = idtourl(reqUserId);
    if(!result)
    {
        uint32_t memberCount = (uint32_t)groupMemberList.size();
        group_obj << "memberCount" << memberCount;
        
        list<member_info_ext_t>::const_iterator itor = groupMemberList.begin();
        for (; itor != groupMemberList.end(); ++itor) {
            jsonxx::Object member_obj;
            member_obj << "memberId" <<itor->user_id;
            member_obj << "memberTitle" << itor->member_title;
            member_obj << "allowPush" << itor->allow_push;
            member_obj << "joinTime" << itor->join_time;
            list_obj << member_obj;
        }
        group_obj << "usersIdList" << list_obj;
        json_obj << "data" << group_obj;
    }
    
    std::string json_str = json_obj.json();
    uint32_t content_len = (uint32_t)json_str.size();
    
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
    return g_response_buf;
}

char* PackGetCreateGroupListResponse(uint32_t reqUserId, const list<uint32_t>& group_list)
{
    jsonxx::Object json_obj, group_obj;
    jsonxx::Array  list_obj;
    
    json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String("getCreateGroupList");
    
    list<uint32_t>::const_iterator itor = group_list.begin();
    for (; itor != group_list.end(); ++itor) {
        list_obj << (*itor);
    }
    
    group_obj << "groupIdList" << list_obj;
    json_obj << "data" << group_obj;
    
    std::string json_str = json_obj.json();
    uint32_t content_len = (uint32_t)json_str.size();
    
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
    return g_response_buf;
}

char* PackChangeGroupMemberResponse(uint32_t reqUserId, uint32_t result, uint16_t commandType, uint32_t groupid, uint32_t userCnt, uint32_t* userIdList)
{
    jsonxx::Object json_obj, group_obj;
    jsonxx::Array  list_obj;
    
	json_obj << "code" << OK_CODE;
    
    if(commandType == IM_PDU_TYPE_GROUP_JOIN_GROUP_RESPONSE)
        json_obj << "type" << jsonxx::String("joinGroup");
    else
        json_obj << "type" << jsonxx::String("quitGroup");
    
    json_obj << "result" << result;
	string id_url = idtourl(reqUserId);
    if(!result)
    {
        group_obj << "groupId" << groupid;
        for (uint32_t i = 0; i < userCnt; ++i) {
            list_obj << userIdList[i];
        }
        group_obj << "usersIdList" << list_obj;
        json_obj << "data" << group_obj;
    }
    
    std::string json_str = json_obj.json();
	uint32_t content_len = (uint32_t)json_str.size();
    
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}


char* PackModifyGroupDescResponse(uint32_t reqUserId, uint32_t result, uint32_t group_id, const string& group_name, const string& group_desc)
{
    jsonxx::Object json_obj;
    
	json_obj << "code" << OK_CODE;
    json_obj << "type" << jsonxx::String("modifyGroupDesc");
    json_obj << "result" << result;
	json_obj << "groupId" << group_id;
    json_obj << "groupName" << jsonxx::String(group_name);
    json_obj << "groupDesc" << jsonxx::String(group_desc);
    
    std::string json_str = json_obj.json();
	uint32_t content_len = (uint32_t)json_str.size();
    
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

/* added by luoning 2014.06.13. */
//返回给php端，目前用不到，由php直接去redis获取
char* PackUnReadCounterResponse(map<uint32_t, map<string, uint32_t> >* user_counter_map)
{
    jsonxx::Object json_obj, user_counter_obj, counter_obj;
	jsonxx::Array user_counter_list;
    
	json_obj << "code" << OK_CODE;
    map<uint32_t, map<string, uint32_t> >::iterator it = user_counter_map->begin();
	for (; it != user_counter_map->end(); it++) {
		user_counter_obj << "userId" << it->first;
        map<string, uint32_t>::iterator it2 = it->second.begin();
        for (; it2 != it->second.end(); it2++) {
            counter_obj << it2->first << it2->second;
        }
		user_counter_obj << "counterType" << counter_obj;
        user_counter_list << user_counter_obj;
		user_counter_obj.reset();
        counter_obj.reset();
	}
    
	json_obj << "data" << user_counter_list;
    
 	std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

//返回给移动端
char* PackUnReadCounterResponse(map<string, uint32_t>* counter_map)
{

    jsonxx::Object json_obj, stats_obj, cinfo_obj, counter_obj;
    
	stats_obj << "code" << OK_CODE;
    stats_obj << "msg" << "success";
    
    map<string, uint32_t>::iterator it = counter_map->begin();
    for (; it != counter_map->end(); it++) {
        //char szvalue[128] = {0};
        //sprintf(szvalue, "%d", it->second);
        counter_obj << it->first << it->second;
    }
    //cinfo_obj <<  "cinfo" << counter_obj;
    json_obj << "status" << stats_obj;
    json_obj << "result" << counter_obj;
    std::string json_str = json_obj.json();
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, (int32_t)json_str.length(), json_str.c_str());
	return g_response_buf;
}

//返回给前端jsonp
char* PackUnReadCounterResponse(const char* callback, map<string, uint32_t>* counter_map)
{
    jsonxx::Object json_obj, counter_obj;
    
	json_obj << "code" << OK_CODE;
    json_obj << "type" << "_imioSocket";
    
    map<string, uint32_t>::iterator it = counter_map->begin();
    for (; it != counter_map->end(); it++) {
        string counter_name = it->first;
        uint32_t counter_value = it->second;
        counter_obj << counter_name << counter_value;
    }
    json_obj << "data" << counter_obj;
    std::string json_str = json_obj.json();
	uint32_t content_len = (int)strlen(callback) + json_str.size() + 2;
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_HEADER, content_len, callback, (char*)json_str.c_str());
	return g_response_buf;
    
}

char* PackPushCntRequest(map<string, uint32_t>* counter_map)
{
    jsonxx::Object json_obj, counter_obj;
    
	json_obj << "code" << OK_CODE;
    json_obj << "type" << "_imioSocket";
    
    map<string, uint32_t>::iterator it = counter_map->begin();
    for (; it != counter_map->end(); it++) {
        counter_obj << it->first << it->second;
    }
    json_obj << "data" << counter_obj;
    std::string json_str = json_obj.json();
    snprintf(g_response_buf, MAX_BUF_SIZE, "%s",json_str.c_str());
	return g_response_buf;
}

/* added end */

char* PackGetLastServiceResponse(uint32_t lastServiceId)
{
    jsonxx::Object json_obj;
    
    if(lastServiceId != (uint32_t)-1) {
        json_obj << "code" << OK_CODE;
    } else {
        json_obj << "code" << 4004;

    }
    json_obj << "lastService" << lastServiceId;
    
    std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();
    
	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

char* PackInsertSysMsgResponse(uint32_t sysMsgId)
{
	jsonxx::Object json_obj;

	if(sysMsgId != (uint32_t)-1) {
		json_obj << "code" << OK_CODE;
	} else {
		json_obj << "code" << 4004;

	}
	json_obj << "sysMsgId" << sysMsgId;

	std::string json_str = json_obj.json();
	uint32_t content_len = json_str.size();

	snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
	return g_response_buf;
}

char* PackUserBadge(uint32_t userIdCnt, user_badge_t* userBadgeList)
{
    jsonxx::Object json_obj, user_badge_obj;
    jsonxx::Array list_obj;
    
    json_obj << "code" << OK_CODE;
    
    for (uint32_t cnt = 0; cnt < userIdCnt; ++cnt) {
        jsonxx::Object badge_obj;
        badge_obj << "userId" << userBadgeList[cnt].user_id;
        badge_obj << "badge" << userBadgeList[cnt].badge;
        list_obj << badge_obj;
    }
    
    user_badge_obj << "user_badge_list" << list_obj;
    json_obj << "data" << user_badge_obj;
    
    std::string json_str = json_obj.json();
    uint32_t content_len = json_str.size();
    
    snprintf(g_response_buf, MAX_BUF_SIZE, HTTP_QUEYR_HEADER, content_len, json_str.c_str());
    return g_response_buf;
}

string& XSSFilter(string& s)
{
    replaceAllSubStr(s, "&", "&amp;");
    replaceAllSubStr(s, ">", "&gt;");
    replaceAllSubStr(s, "<", "&lt;");
    replaceAllSubStr(s, "\"", "&quot;");
    replaceAllSubStr(s, "'", "&#x27;");
    return s;
}